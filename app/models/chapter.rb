#encoding: utf-8
class Chapter < ActiveRecord::Base
  include ImageHandler
  include Constant
  
  belongs_to :course, :counter_cache => true
  has_many :rounds, :dependent => :destroy
  mount_uploader :img, AvatarUploader

  validates :name, :uniqueness => { :scope => :course_id,
    :message =>  "同一课程下章节名称已存在！" }

  scope :verified, where(:status => VARIFY_STATUS[:verified])
  after_destroy :remove_image_after_deleted

end
