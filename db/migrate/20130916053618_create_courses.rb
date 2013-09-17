class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.string :name
      t.string :press
      t.text :description
      t.string :img
      t.integer :types
      t.integer :status
      t.integer :time_ratio
      t.integer :blood
      t.integer :max_score

      t.timestamps
    end
  end
end
