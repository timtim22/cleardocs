class Document < ApplicationRecord
  belongs_to :user
  has_one_attached :file

  validates :title, presence: true
  validates :file, presence: true

  def file_url
    return nil unless file.attached?
    
    if Rails.env.development?
      Rails.application.routes.url_helpers.rails_blob_url(file, host: 'localhost:3000')
    else
      file.url
    end
  end
end
