require 'pdf-reader'
require 'docx'
require 'tempfile'
require 'rtesseract'
require 'mini_magick'

class DocumentTextExtractionService
  attr_reader :document

  def initialize(document)
    @document = document
  end

  def self.extract(document)
    new(document).extract
  end

  def extract
    return { success: false, error: 'No file attached' } unless document.file.attached?

    begin
      document.update(processing_status: :processing)
      
      file_content = document.file.download
      
      result = case document.file.content_type
      when 'application/pdf'
        extract_text_from_pdf(file_content)
      when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        extract_text_from_docx(file_content)
      when 'text/plain'
        extract_text_from_txt(file_content)
      else
        return { success: false, error: 'Unsupported file type' }
      end

      if result[:page_texts].present?
        # Combine all page texts for full-text search
        full_text = result[:page_texts].values.join("\n\n")
        
        document.update(
          page_texts: result[:page_texts],
          extracted_text: full_text,
          page_count: result[:page_count],
          processing_status: :completed
        )
        
        { 
          success: true, 
          text_length: full_text.length,
          page_count: result[:page_count],
          message: "Successfully extracted #{full_text.length} characters from #{result[:page_count]} page(s)"
        }
      else
        document.update(processing_status: :failed)
        { success: false, error: 'No text could be extracted from file' }
      end
    rescue => e
      Rails.logger.error "Text extraction failed for document #{document.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      document.update(processing_status: :failed)
      { success: false, error: e.message }
    end
  end

  private

  def extract_text_from_pdf(file_content)
    Tempfile.create(['document', '.pdf']) do |temp_file|
      temp_file.binmode
      temp_file.write(file_content)
      temp_file.rewind

      reader = PDF::Reader.new(temp_file.path)
      page_texts = {}
      scanned_pages = 0
      
      # Limit to first 100 pages to prevent timeout
      pages_to_process = [reader.page_count, 100].min
      
      (1..pages_to_process).each do |page_num|
        begin
          page = reader.page(page_num)
          page_text = page.text.strip
          
          # Check if page appears to be scanned (no text or very little text)
          if page_text.empty? || page_text.length < 50
            Rails.logger.info "Page #{page_num} appears to be scanned (#{page_text.length} chars), attempting OCR..."
            ocr_text = ocr_pdf_page(temp_file.path, page_num)
            
            if ocr_text.present? && ocr_text.length > page_text.length
              page_texts[page_num.to_s] = ocr_text
              scanned_pages += 1
              Rails.logger.info "OCR successful for page #{page_num}: extracted #{ocr_text.length} characters"
            else
              page_texts[page_num.to_s] = page_text
            end
          else
            page_texts[page_num.to_s] = page_text
          end
        rescue => e
          Rails.logger.warn "Failed to extract text from page #{page_num}: #{e.message}"
          page_texts[page_num.to_s] = "[Error extracting text from this page]"
        end
      end
      
      total_chars = page_texts.values.join.length
      Rails.logger.info "Extracted #{total_chars} characters from #{pages_to_process} pages (#{scanned_pages} pages used OCR)"
      
      { page_texts: page_texts, page_count: pages_to_process }
    end
  end

  def extract_text_from_docx(file_content)
    Tempfile.create(['document', '.docx']) do |temp_file|
      temp_file.binmode
      temp_file.write(file_content)
      temp_file.rewind

      doc = Docx::Document.open(temp_file.path)
      paragraphs = []
      
      doc.paragraphs.each do |paragraph|
        paragraph_text = paragraph.text.strip
        paragraphs << paragraph_text unless paragraph_text.empty?
      end
      
      # DOCX doesn't have pages in the same way as PDF, so treat it as one "page"
      full_text = paragraphs.join("\n\n")
      
      { page_texts: { "1" => full_text }, page_count: 1 }
    end
  end

  def extract_text_from_txt(file_content)
    # TXT files are simple - just one "page"
    text = file_content.force_encoding('UTF-8')
    
    { page_texts: { "1" => text }, page_count: 1 }
  end

  def ocr_pdf_page(pdf_path, page_num)
    # Convert PDF page to image using MiniMagick, then OCR it
    begin
      # Create temporary file for the image
      Tempfile.create(['page', '.png']) do |image_file|
        # Convert PDF page to PNG image
        # Format: pdf_path[page_num-1] gets specific page (0-indexed)
        image = MiniMagick::Image.open("#{pdf_path}[#{page_num - 1}]")
        
        # Optimize image for OCR
        image.format 'png'
        image.colorspace 'Gray'  # Convert to grayscale
        image.density '300'      # High DPI for better OCR
        image.quality '100'
        
        image.write(image_file.path)
        
        # Perform OCR on the image
        ocr = RTesseract.new(image_file.path, lang: 'eng')
        ocr_text = ocr.to_s.strip
        
        return ocr_text
      end
    rescue => e
      Rails.logger.error "OCR failed for page #{page_num}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      return ""
    end
  end
end
