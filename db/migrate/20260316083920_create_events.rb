class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title
      t.text :description
      t.integer :event_type
      t.datetime :start_datetime
      t.datetime :end_datetime
      t.string :location
      t.integer :target_audience
      t.boolean :registration_required

      t.timestamps
    end
  end
end
