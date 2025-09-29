class HomeController < ApplicationController
  before_action :authenticate_user!, only: [:index, :upload_document]

  def index
    if user_signed_in?
      @welcome_message = "Welcome to ClearDocs"
    else
      @welcome_message = "Please sign in to access ClearDocs"
    end
  end

  def upload_document
    if params[:document].present?
      uploaded_file = params[:document]
      
      document = current_user.documents.build(
        title: uploaded_file.original_filename,
        file: uploaded_file
      )
      
      if document.save
        flash[:notice] = "Document '#{uploaded_file.original_filename}' uploaded successfully!"
      else
        flash[:alert] = "Failed to upload document. Please try again."
      end
    else
      flash[:alert] = "Please select a file to upload."
    end
    redirect_to root_path
  end
end
