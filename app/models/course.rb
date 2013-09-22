class Course < ActiveRecord::Base
  has_many :chapters, :dependent => :destroy
  has_many :rounds, :dependent => :destroy

  mount_uploader :img, AvatarUploader
  validates :name, :types, :press, :description, :img, :max_score, :blood, :round_time, :time_ratio, :presence => true
end
