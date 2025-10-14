require 'pdf-reader'
require 'docx'
require 'tempfile'

class Document < ApplicationRecord
  belongs_to :user
  has_one_attached :file

  validates :title, presence: true
  validates :file, presence: true
  validate :acceptable_file_type

  # extracted_text column stores the text content extracted from PDF/DOCX files
  after_create :extract_text_from_file
  after_update :extract_text_from_file, if: :saved_change_to_file?

  def file_url
    return nil unless file.attached?
    
    if Rails.env.development?
      Rails.application.routes.url_helpers.rails_blob_url(file, host: 'localhost:3000')
    else
      file.url
    end
  end

  def has_extracted_text?
    extracted_text.present?
  end

  def extract_text!
    extracted_content = extract_text_from_attached_file
    update_column(:extracted_text, extracted_content) if extracted_content.present?
  end

  private

  def extract_text_from_file
    return unless file.attached?
    
    # For immediate extraction (synchronous) - useful for testing
    if Rails.env.development? || Rails.env.test?
      extract_text!
    else
      # Use a background job for text extraction to avoid blocking the main thread
      ExtractTextJob.perform_later(self)
    end
  end

  def extract_text_from_attached_file
    return nil unless file.attached?

    # Get the file content
    file_content = file.download
    
    # Determine extraction method based on content type
    case file.content_type
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

  def extract_text_from_pdf(file_content)
    # Create a temporary file to work with pdf-reader
    Tempfile.create(['document', '.pdf']) do |temp_file|
      temp_file.binmode
      temp_file.write(file_content)
      temp_file.rewind

      reader = PDF::Reader.new(temp_file.path)
      text_content = []
      
      # Limit to first 50 pages to prevent timeout
      pages_to_process = [reader.page_count, 50].min
      
      (1..pages_to_process).each do |page_num|
        begin
          page = reader.page(page_num)
          page_text = page.text.strip
          text_content << page_text unless page_text.empty?
        rescue => e
          Rails.logger.warn "Failed to extract text from page #{page_num}: #{e.message}"
          next
        end
      end
      
      extracted_text = text_content.join("\n\n")
      Rails.logger.info "Extracted #{extracted_text.length} characters from #{pages_to_process} pages"
      extracted_text
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

  def acceptable_file_type
    return unless file.attached?

    acceptable_types = ['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
    unless acceptable_types.include?(file.blob.content_type)
      errors.add(:file, 'must be a PDF or DOCX file')
    end

    # Also check file extension as a backup
    if file.blob.filename.present?
      extension = File.extname(file.blob.filename.to_s).downcase
      unless ['.pdf', '.docx'].include?(extension)
        errors.add(:file, 'must have a .pdf or .docx extension')
      end
    end
  end
end
