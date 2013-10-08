class AddTypesToBranchQuestions < ActiveRecord::Migration
  def change
    add_column :branch_questions, :types, :integer, :limit => 1  #给小题加题型字段
  end
end
