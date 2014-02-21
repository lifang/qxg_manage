class AddFunctionTypesToProps < ActiveRecord::Migration
  def change
    add_column :props, :function_type, :integer, :limit => 2
  end
end
