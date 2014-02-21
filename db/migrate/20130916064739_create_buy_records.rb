class CreateBuyRecords < ActiveRecord::Migration
  def change
    create_table :buy_records do |t|
      t.integer :user_id
      t.integer :course_id
      t.integer :prop_id
      t.integer :count
      t.integer :gold
      t.integer :types

      t.timestamps
    end
    add_index :buy_records,:user_id
    add_index :buy_records,:course_id
    add_index :buy_records,:prop_id
  end
end
