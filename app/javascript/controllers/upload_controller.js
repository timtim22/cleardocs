import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "loadingModal", "loadingMessage", "progressBar"]

  connect() {
    // Bind the form submit event
    if (this.hasFormTarget) {
      this.formTarget.addEventListener("submit", this.handleSubmit.bind(this))
    }
  }

  handleSubmit(event) {
    const fileInput = document.getElementById('document-upload')
    
    if (!fileInput || !fileInput.files || fileInput.files.length === 0) {
      return
    }

    const file = fileInput.files[0]
    const fileSizeInMB = file.size / (1024 * 1024)
    
    // Show loading modal
    this.showLoadingModal(file.name, fileSizeInMB)
  }

  showLoadingModal(fileName, fileSizeInMB) {
    // Create loading modal
    const modal = document.createElement('div')
    modal.id = 'upload-loading-modal'
    modal.className = 'fixed inset-0 bg-black bg-opacity-75 z-[100] flex items-center justify-center p-4'
    modal.innerHTML = `
      <div class="bg-white rounded-lg p-8 max-w-md w-full">
        <div class="text-center">
          <!-- Spinner -->
          <div class="inline-block animate-spin rounded-full h-16 w-16 border-b-4 border-t-4 border-indigo-600 mb-4"></div>
          
          <!-- Title -->
          <h3 class="text-xl font-semibold text-gray-900 mb-2">Processing Your Document</h3>
          
          <!-- File info -->
          <p class="text-sm text-gray-600 mb-4 break-all">${fileName}</p>
          
          <!-- Status message -->
          <div class="space-y-2 text-left bg-gray-50 rounded-lg p-4">
            <div class="flex items-center text-sm text-gray-700">
              <svg class="w-5 h-5 mr-2 text-green-500 animate-pulse" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
              </svg>
              <span>Uploading document...</span>
            </div>
            <div class="flex items-center text-sm text-gray-700">
              <svg class="w-5 h-5 mr-2 text-blue-500 animate-pulse" fill="currentColor" viewBox="0 0 20 20">
                <path d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z"/>
                <path fill-rule="evenodd" d="M4 5a2 2 0 012-2 3 3 0 003 3h2a3 3 0 003-3 2 2 0 012 2v11a2 2 0 01-2 2H6a2 2 0 01-2-2V5zm3 4a1 1 0 000 2h.01a1 1 0 100-2H7zm3 0a1 1 0 000 2h3a1 1 0 100-2h-3zm-3 4a1 1 0 100 2h.01a1 1 0 100-2H7zm3 0a1 1 0 100 2h3a1 1 0 100-2h-3z" clip-rule="evenodd"/>
              </svg>
              <span>Extracting text from ${fileSizeInMB > 5 ? 'large ' : ''}document...</span>
            </div>
          </div>
          
          <!-- Progress bar -->
          <div class="mt-4 w-full bg-gray-200 rounded-full h-2 overflow-hidden">
            <div class="bg-indigo-600 h-2 rounded-full animate-pulse" style="width: 70%; animation: loading 2s ease-in-out infinite;"></div>
          </div>
          
          <p class="text-xs text-gray-500 mt-4">
            ${fileSizeInMB > 5 ? 'This may take a moment for larger files...' : 'Please wait...'}
          </p>
        </div>
      </div>
    `
    
    // Add animation style
    const style = document.createElement('style')
    style.textContent = `
      @keyframes loading {
        0%, 100% { width: 40%; }
        50% { width: 80%; }
      }
    `
    document.head.appendChild(style)
    
    document.body.appendChild(modal)
  }
}
