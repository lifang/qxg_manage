class AddRoundCountToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :round_count, :int
  end
end
