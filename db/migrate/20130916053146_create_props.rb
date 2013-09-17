class CreateProps < ActiveRecord::Migration
  def change
    create_table :props do |t|
      t.integer :course_id
      t.string :name
      t.text :description
      t.integer :price
      t.integer :types
      t.integer :question_types
      t.string :img

      t.timestamps
    end
    add_index :props,:course_id
  end
end
