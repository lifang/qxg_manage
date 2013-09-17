class CreateAchieveCounts < ActiveRecord::Migration
  def change
    create_table :achieve_counts do |t|
      t.integer :user_id
      t.integer :course_id
      t.integer :chapter_id
      t.integer :round_id
      t.integer :prop_id
      t.integer :types

      t.timestamps
    end
    add_index :achieve_counts,:user_id
    add_index :achieve_counts,:course_id
    add_index :achieve_counts,:chapter_id
    add_index :achieve_counts,:round_id
    add_index :achieve_counts,:prop_id
  end
end
