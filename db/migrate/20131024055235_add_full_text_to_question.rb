class AddFullTextToQuestion < ActiveRecord::Migration
  def change
    add_column :questions, :full_text, :text
  end
end
