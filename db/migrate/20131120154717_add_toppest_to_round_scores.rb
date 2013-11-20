class AddToppestToRoundScores < ActiveRecord::Migration
  def change
    add_column :round_scores, :toppest_count, :integer #某一关卡用户排名第一的次数，累加
  end
end
