class CreateUserCardsRelations < ActiveRecord::Migration
  def change
    create_table :user_cards_relations do |t|
      t.integer :user_id
      t.integer :knowledge_card_id
      t.string :remark

      t.timestamps
    end
    add_index :user_cards_relations,:user_id
  end
end
