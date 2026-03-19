# frozen_string_literal: true

class AddOrganizerAndMaxParticipantsToEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :events, :organizer, null: true, foreign_key: { to_table: :users }
    add_column :events, :max_participants, :integer, null: true
  end
end
