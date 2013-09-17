class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :password
      t.string :name
      t.datetime :birthday
      t.boolean :sex
      t.string :img
      t.string :phone
      t.integer :weibo_id
      t.datetime :weibo_time
      t.integer :types

      t.timestamps
    end
  end
end
