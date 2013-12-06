class ChangeDefaultValueOfProps < ActiveRecord::Migration
  def up
    change_column :props, :status, :boolean, :default => 0
  end

  def down
  end
end
