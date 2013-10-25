class RenameRoundCountToRoundsCount < ActiveRecord::Migration
  def change
    rename_column :chapters, :round_count, :rounds_count  
    add_column :courses, :chapters_count, :integer, :default => 0
  end

end
