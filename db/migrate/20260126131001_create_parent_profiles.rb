class CreateParentProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :parent_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :occupation
      t.string :employer
      t.text :address

      t.timestamps
    end
  end
end
