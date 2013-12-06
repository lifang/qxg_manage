class CreateUserPropRelations < ActiveRecord::Migration
  def change
    create_table :user_prop_relations do |t|
      t.integer :user_id
      t.integer :prop_id
      t.integer :user_prop_num

      t.timestamps
    end
    add_index :user_prop_relations,:user_id
    add_index :user_prop_relations,:prop_id
  end
end
