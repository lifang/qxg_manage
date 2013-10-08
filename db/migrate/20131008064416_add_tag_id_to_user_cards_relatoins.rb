class AddTagIdToUserCardsRelatoins < ActiveRecord::Migration
  def change
    add_column :user_cards_relations, :cardbag_tag_id, :integer
  end
end
