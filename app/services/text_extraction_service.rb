require 'pdf-reader'
require 'docx'
require 'tempfile'

class TextExtractionService
  class << self
    def extract_text_from_file(file_attachment)
      return nil unless file_attachment.attached?

      # Get the file content
      file_content = file_attachment.download
      
      # Determine extraction method based on content type
      case file_attachment.content_type
      when 'application/pdf'
        extract_text_from_pdf(file_content)
      when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        extract_text_from_docx(file_content)
      else
        nil
      end
    rescue => e
      Rails.logger.error "Text extraction failed: #{e.message}"
      nil
    end

    private

    def extract_text_from_pdf(file_content)
      # Create a temporary file to work with pdf-reader
      Tempfile.create(['document', '.pdf']) do |temp_file|
        temp_file.binmode
        temp_file.write(file_content)
        temp_file.rewind

        reader = PDF::Reader.new(temp_file.path)
        text_content = []
        
        reader.pages.each do |page|
          page_text = page.text.strip
          text_content << page_text unless page_text.empty?
        end
        
        text_content.join("\n\n")
      end
    end

    def extract_text_from_docx(file_content)
      # Create a temporary file to work with docx gem
      Tempfile.create(['document', '.docx']) do |temp_file|
        temp_file.binmode
        temp_file.write(file_content)
        temp_file.rewind

        doc = Docx::Document.open(temp_file.path)
        text_content = []
        
        doc.paragraphs.each do |paragraph|
          paragraph_text = paragraph.text.strip
          text_content << paragraph_text unless paragraph_text.empty?
        end
        
        text_content.join("\n\n")
      end
    end
  end
end
