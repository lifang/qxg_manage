class CreateUserMistakeQuestions < ActiveRecord::Migration
  def change
    create_table :user_mistake_questions do |t|
      t.integer :user_id
      t.integer :course_id
      t.integer :question_id
      t.datetime :wrong_time

      t.timestamps
    end
    add_index :user_mistake_questions,:user_id
    add_index :user_mistake_questions,:course_id
    add_index :user_mistake_questions,:question_id
  end
end
