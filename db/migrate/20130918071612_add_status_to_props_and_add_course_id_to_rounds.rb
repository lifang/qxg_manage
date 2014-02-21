class AddStatusToPropsAndAddCourseIdToRounds < ActiveRecord::Migration
  def change
    add_column :props, :status, :boolean
    add_column :rounds, :course_id, :integer
    add_column :courses, :round_time, :integer
  end
end
