class CreateKnowledgeCards < ActiveRecord::Migration
  def change
    create_table :knowledge_cards do |t|
      t.string :name
      t.text :description
      t.integer :course_id
      t.integer :types

      t.timestamps
    end
    add_index :knowledge_cards,:course_id
  end
end
