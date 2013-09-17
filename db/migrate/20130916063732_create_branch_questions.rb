class CreateBranchQuestions < ActiveRecord::Migration
  def change
    create_table :branch_questions do |t|
      t.text :branch_content
      t.string :answer
      t.string :options
      t.integer :question_id

      t.timestamps
    end
    add_index :branch_questions,:question_id
  end
end
