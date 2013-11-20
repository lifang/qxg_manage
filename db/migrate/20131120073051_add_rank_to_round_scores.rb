class AddRankToRoundScores < ActiveRecord::Migration
  def change
    add_column :round_scores, :rank, :integer, :limit => 1 #用户当前关卡排名
  end
end
