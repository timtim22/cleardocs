class Document < ApplicationRecord
  belongs_to :user
  belongs_to :foia_request, optional: true
  has_one_attached :file

  # Processing status enum
  enum :processing_status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }

  validates :title, presence: true
  validates :file, presence: true
  validate :acceptable_file_type

  # Callbacks
  after_initialize :set_default_processing_status, if: :new_record?
  before_save :set_file_metadata

  # Scopes
  scope :by_foia_request, ->(request_id) { where(foia_request_id: request_id) }
  scope :processed, -> { where(processing_status: :completed) }
  scope :unprocessed, -> { where.not(processing_status: :completed) }

  def file_url
    return nil unless file.attached?
    
    if Rails.env.development?
      Rails.application.routes.url_helpers.rails_blob_url(file, host: 'localhost:3000')
    else
      file.url
    end
  end

  def has_extracted_text?
    extracted_text.present? || page_texts.present?
  end

  def get_page_text(page_number)
    return nil unless page_texts.present?
    page_texts[page_number.to_s]
  end

  def total_pages
    page_count || 0
  end

  def file_extension
    return nil unless file.attached?
    File.extname(file.blob.filename.to_s).downcase
  end

  def file_icon_class
    case file_extension
    when '.pdf'
      'text-red-500'
    when '.docx'
      'text-blue-600'
    when '.txt'
      'text-gray-600'
    else
      'text-gray-500'
    end
  end

  def formatted_file_size
    return 'N/A' unless file_size_bytes.present?
    
    if file_size_bytes < 1024
      "#{file_size_bytes} B"
    elsif file_size_bytes < 1024 * 1024
      "#{(file_size_bytes / 1024.0).round(2)} KB"
    else
      "#{(file_size_bytes / (1024.0 * 1024)).round(2)} MB"
    end
  end

  private

  def acceptable_file_type
    return unless file.attached?

    acceptable_types = [
      'application/pdf',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain'
    ]
    
    unless acceptable_types.include?(file.blob.content_type)
      errors.add(:file, 'must be a PDF, DOCX, or TXT file')
    end

    # Also check file extension as a backup
    if file.blob.filename.present?
      extension = File.extname(file.blob.filename.to_s).downcase
      unless ['.pdf', '.docx', '.txt'].include?(extension)
        errors.add(:file, 'must have a .pdf, .docx, or .txt extension')
      end
    end
  end

  def set_default_processing_status
    self.processing_status ||= :pending
  end

  def set_file_metadata
    return unless file.attached?
    return if file_type.present? && file_size_bytes.present? # Already set
    
    self.file_type = file.blob.content_type
    self.file_size_bytes = file.blob.byte_size
  end
end
