class ExtractTextJob < ApplicationJob
  queue_as :default

  def perform(document)
    return unless document.file.attached?

    begin
      document.extract_text!
      
      if document.reload.has_extracted_text?
        Rails.logger.info "Successfully extracted text from document #{document.id}: #{document.title}"
      else
        Rails.logger.warn "No text could be extracted from document #{document.id}: #{document.title}"
      end
    rescue => e
      Rails.logger.error "Failed to extract text from document #{document.id}: #{e.message}"
    end
  end
end
