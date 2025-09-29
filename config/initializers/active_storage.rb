# Configure Active Storage URL options
Rails.application.configure do
  # Set default URL options for Active Storage
  if Rails.env.development?
    config.after_initialize do
      ActiveStorage::Current.url_options = {
        host: 'localhost',
        port: 3000,
        protocol: 'http'
      }
    end
  end
end
