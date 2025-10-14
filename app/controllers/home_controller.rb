class HomeController < ApplicationController
  before_action :authenticate_user!, only: [:index, :upload_document, :delete_document]

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
        # Check if the error is related to file type
        if document.errors[:file].any?
          file_errors = document.errors[:file].join(', ')
          flash[:alert] = "Upload failed: #{file_errors}. Only PDF and DOCX files are supported."
        else
          flash[:alert] = "Failed to upload document. Please try again."
        end
      end
    else
      flash[:alert] = "Please select a file to upload."
    end
    redirect_to root_path
  end

  def delete_document
    @document = current_user.documents.find(params[:id])
    
    if @document.destroy
      flash[:notice] = "Document '#{@document.title}' deleted successfully!!!!"
    else
      flash[:alert] = "Failed to delete document. Please try again."
    end
    redirect_to root_path
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Document not found."
    redirect_to root_path
  end

  def view_text
    @document = current_user.documents.find(params[:id])
    
    unless @document.has_extracted_text?
      flash[:alert] = "Text extraction is still in progress for this document."
      redirect_to root_path
      return
    end
    
    render json: {
      title: @document.title,
      extracted_text: @document.extracted_text,
      character_count: @document.extracted_text.length
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Document not found" }, status: :not_found
  end
end
