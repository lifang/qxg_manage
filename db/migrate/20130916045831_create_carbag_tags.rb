class CreateCarbagTags < ActiveRecord::Migration
  def change
    create_table :carbag_tags do |t|
      t.integer :user_id
      t.integer :course_id
      t.string :name
      t.integer :types, :default => 0

      t.timestamps
    end
    add_index :carbag_tags,:user_id
    add_index :carbag_tags,:course_id
  end
end
