class CreateChapters < ActiveRecord::Migration
  def change
    create_table :chapters do |t|
      t.integer :course_id
      t.string :name
      t.string :img
      t.integer :round_count

      t.timestamps
    end
    add_index :chapters,:course_id
  end
end
