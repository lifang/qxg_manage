class CreateAchieveData < ActiveRecord::Migration
  def change
    create_table :achieve_data do |t|
      t.string :name
      t.string :requirement
      t.string :img
      t.integer :points

      t.timestamps
    end
  end
end
