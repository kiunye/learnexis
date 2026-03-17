class CreateNotices < ActiveRecord::Migration[8.1]
  def change
    create_table :notices do |t|
      t.string :title
      t.text :content
      t.integer :priority
      t.integer :notice_type
      t.integer :target_audience
      t.string :grade_levels, default: ""  # Comma-separated list of grade levels for grade-specific notices
      t.datetime :published_at
      t.datetime :expires_at
      t.boolean :active, default: true
      t.references :author, foreign_key: { to_table: :users }

      t.timestamps
    end

    # Add indexes for common queries
    add_index :notices, :published_at
    add_index :notices, :expires_at
    add_index :notices, :active
    add_index :notices, :priority
    add_index :notices, :target_audience
  end
end
