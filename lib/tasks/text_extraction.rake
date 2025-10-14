namespace :documents do
  desc "Extract text from all documents that don't have extracted text"
  task extract_text: :environment do
    documents_without_text = Document.where(extracted_text: [nil, ''])
    
    puts "Found #{documents_without_text.count} documents without extracted text"
    
    documents_without_text.find_each do |document|
      if document.file.attached?
        puts "Extracting text from: #{document.title}"
        document.extract_text!
        
        if document.reload.has_extracted_text?
          puts "✓ Successfully extracted text (#{document.extracted_text.length} characters)"
        else
          puts "✗ Failed to extract text"
        end
      else
        puts "✗ No file attached for: #{document.title}"
      end
    end
    
    puts "Text extraction completed!"
  end

  desc "Show extracted text for a specific document"
  task :show_text, [:document_id] => :environment do |task, args|
    document_id = args[:document_id]
    
    if document_id.blank?
      puts "Please provide a document ID: rake documents:show_text[1]"
      exit
    end
    
    document = Document.find(document_id)
    
    puts "Document: #{document.title}"
    puts "File attached: #{document.file.attached?}"
    puts "Has extracted text: #{document.has_extracted_text?}"
    
    if document.has_extracted_text?
      puts "\n--- Extracted Text ---"
      puts document.extracted_text
      puts "\n--- End of Text (#{document.extracted_text.length} characters) ---"
    else
      puts "No extracted text available"
    end
  rescue ActiveRecord::RecordNotFound
    puts "Document with ID #{document_id} not found"
  end
end
