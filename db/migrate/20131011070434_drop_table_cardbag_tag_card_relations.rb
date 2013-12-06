class DropTableCardbagTagCardRelations < ActiveRecord::Migration
  def change
    drop_table :cardbag_tag_card_relations
  end
end
