class AddStarToRoundScores < ActiveRecord::Migration
  def change
    add_column :round_scores, :star,:integer, :limit => 1
  end
end
