class AddFoiaFieldsToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_reference :documents, :foia_request, null: true, foreign_key: true, index: true
    add_column :documents, :page_texts, :jsonb, default: {}
    add_column :documents, :processing_status, :integer, default: 0
    add_column :documents, :file_type, :string
    add_column :documents, :file_size_bytes, :bigint
    add_column :documents, :page_count, :integer, default: 0
    
    add_index :documents, :processing_status
  end
end
