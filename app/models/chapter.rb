class Chapter < ActiveRecord::Base
  belongs_to :course
  mount_uploader :img, AvatarUploader
end
