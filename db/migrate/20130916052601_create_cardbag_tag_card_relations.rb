class CreateCardbagTagCardRelations < ActiveRecord::Migration
  def change
    create_table :cardbag_tag_card_relations do |t|
      t.integer :cardbag_tag_id
      t.integer :card_id

      t.timestamps
    end
    add_index :cardbag_tag_card_relations,:cardbag_tag_id
    add_index :cardbag_tag_card_relations,:card_id
  end
end
