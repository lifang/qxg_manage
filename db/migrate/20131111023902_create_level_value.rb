class CreateLevelValue < ActiveRecord::Migration
 def change
    create_table :level_values do |t|
      t.integer :course_id
      t.integer :level
      t.integer :experience_value
    end
  end
end
