class AddExperienceValueToUserCourseRelations < ActiveRecord::Migration
  def change
    add_column :user_course_relations, :experience_value, :integer
  end
end
