Rails.application.routes.draw do
  # Devise routes
  devise_for :users
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Home Routes
  root "home#index"
  post "upload_document", to: "home#upload_document"
  post "extract_text/:id", to: "home#extract_text", as: :extract_text
  delete "delete_document/:id", to: "home#delete_document", as: :delete_document
  get "view_text/:id", to: "home#view_text", as: :view_document_text
end
