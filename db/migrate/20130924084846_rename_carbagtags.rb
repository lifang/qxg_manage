class RenameCarbagtags < ActiveRecord::Migration
  def up
    rename_table :carbag_tags, :cardbag_tags
  end

  def down
  end
end
