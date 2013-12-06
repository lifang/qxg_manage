class CreateUserCourseRelations < ActiveRecord::Migration
  def change
    create_table :user_course_relations do |t|
      t.integer :user_id
      t.integer :course_id
      t.integer :cardbag_count,:default => 0
      t.integer :cardbag_use_count,:default => 0
      t.integer :gold,:default => 0
      t.integer :gold_total,:default => 0
      t.integer :level, :default => 1
      t.integer :achieve_point, :default => 0

      t.timestamps
    end
      add_index :user_course_relations,:user_id
    add_index :user_course_relations,:course_id
  end
end
