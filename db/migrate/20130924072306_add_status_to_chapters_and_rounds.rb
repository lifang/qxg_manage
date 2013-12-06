class AddStatusToChaptersAndRounds < ActiveRecord::Migration
  #章节、关卡、课程加个status判断是否审核过
  def change
    add_column :chapters, :status, :integer, :limit => 1, :default => 0
    add_column :rounds, :status, :integer, :limit => 1, :default => 0
    change_column :courses, :status, :integer, :limit => 1, :default => 0
  end
end
