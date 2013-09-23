class Chapter < ActiveRecord::Base
  belongs_to :course
  has_many :rounds
  mount_uploader :img, AvatarUploader
end
