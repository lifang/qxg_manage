class AddToppestFlagToRoundScores < ActiveRecord::Migration
  def change
    add_column :round_scores, :toppest_flag, :boolean, :default => false
    add_column :round_scores, :star_3flag, :boolean, :default => false
    add_column :round_scores, :best_score, :integer, :default => 0
  end
end
