class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.text :content
      t.integer :types
      t.integer :knowledge_card_id
      t.integer :round_id

      t.timestamps
    end
    add_index :questions,:round_id
  end
end
