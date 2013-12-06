class CreateRounds < ActiveRecord::Migration
  def change
    create_table :rounds do |t|
      t.integer :chapter_id
      t.string :name
      t.integer :questions_count
      t.integer :round_time
      t.integer :time_ratio
      t.integer :blood
      t.integer :max_score

      t.timestamps
    end
    add_index :rounds,:chapter_id
  end
end
