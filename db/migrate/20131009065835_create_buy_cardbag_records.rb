class CreateBuyCardbagRecords < ActiveRecord::Migration
  def change
    create_table :buy_cardbag_records do |t|
      t.integer :user_id
      t.integer :course_id
      t.integer :num
      t.integer :gold

      t.timestamps
    end
  end
end
