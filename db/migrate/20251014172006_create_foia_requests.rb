class CreateFoiaRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :foia_requests do |t|
      t.string :request_number
      t.string :requester_name
      t.string :requester_email
      t.string :requester_organization
      t.string :subject
      t.text :description
      t.datetime :received_at
      t.datetime :due_on
      t.integer :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :foia_requests, :request_number, unique: true
  end
end
