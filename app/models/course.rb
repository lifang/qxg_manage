#encoding: utf-8
class Course < ActiveRecord::Base
  has_many :chapters, :dependent => :destroy
  has_many :rounds, :dependent => :destroy

  mount_uploader :img, AvatarUploader

  TYPES = {0 => "英语四级", 1 => "英语六级", 2 => "托福口语", 3 => "雅思"}
end
