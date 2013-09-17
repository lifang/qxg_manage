class CreateRoundScores < ActiveRecord::Migration
  def change
    create_table :round_scores do |t|
      t.integer :user_id
      t.integer :chapter_id
      t.integer :round_id
      t.integer :score
      t.datetime :day

      t.timestamps
    end
    add_index :round_scores,:user_id
    add_index :round_scores,:chapter_id
    add_index :round_scores,:round_id
  end
end
