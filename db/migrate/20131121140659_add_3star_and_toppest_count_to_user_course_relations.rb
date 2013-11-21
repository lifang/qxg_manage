class Add3starAndToppestCountToUserCourseRelations < ActiveRecord::Migration
  def change
    remove_column :round_scores, :toppest_count
    add_column :user_course_relations, :round_toppest_count, :integer, :default => 0
    add_column :user_course_relations, :round_3star_count, :integer, :default => 0
  end
end
