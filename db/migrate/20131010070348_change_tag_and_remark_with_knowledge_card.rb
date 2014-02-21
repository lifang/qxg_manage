class ChangeTagAndRemarkWithKnowledgeCard < ActiveRecord::Migration
  def change
    remove_column :user_cards_relations, :cardbag_tag_id
    add_column :user_cards_relations, :course_id, :integer

     create_table :card_tag_relations do |t|
      t.integer :user_id
      t.integer :course_id
      t.integer :knowledge_card_id
      t.integer :cardbag_tag_id

      t.timestamps
    end
  end

end
