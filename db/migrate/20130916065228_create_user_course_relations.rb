class CreateUserCourseRelations < ActiveRecord::Migration
  def change
    create_table :user_course_relations do |t|
      t.integer :user_id
      t.integer :course_id
      t.integer :cardbag_count
      t.integer :cardbag_use_count
      t.integer :gold
      t.integer :gold_total
      t.integer :level
      t.integer :achieve_point

      t.timestamps
    end
      add_index :user_course_relations,:user_id
    add_index :user_course_relations,:course_id
  end
end
