class CreateAchieves < ActiveRecord::Migration
  def change
    create_table :achieves do |t|
      t.integer :user_id
      t.integer :course_id
      t.integer :achieve_data_id
      t.integer :point

      t.timestamps
    end
    add_index :achieves,:user_id
    add_index :achieves,:course_id
    add_index :achieves,:achieve_data_id
  end
end
