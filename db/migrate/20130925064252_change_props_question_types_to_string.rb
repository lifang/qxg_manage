class ChangePropsQuestionTypesToString < ActiveRecord::Migration
  def up
    change_column :props, :question_types, :string
  end

  def down
  end
end
