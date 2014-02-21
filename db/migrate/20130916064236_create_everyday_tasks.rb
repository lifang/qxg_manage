class CreateEverydayTasks < ActiveRecord::Migration
  def change
    create_table :everyday_tasks do |t|
      t.integer :user_id
      t.integer :course_id
      t.integer :day
      t.datetime :update_time

      t.timestamps
    end
    add_index :everyday_tasks,:user_id
    add_index :everyday_tasks,:course_id
  end
end
