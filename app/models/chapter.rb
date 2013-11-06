#encoding: utf-8
class Chapter < ActiveRecord::Base
  include ImageHandler
  
  belongs_to :course, :counter_cache => true
  has_many :rounds, :dependent => :destroy
  mount_uploader :img, AvatarUploader
  
  STATUS_NAME = { 0 => "未审核", 1 => "已审核"}
  STATUS = {:not_verified => 0, :verified => 1}

  validates :name, :uniqueness => { :scope => :course_id,
    :message =>  "同一课程下章节名称已存在！" }

  scope :verified, where(:status => STATUS[:verified])
  after_destroy :remove_image_after_deleted

end
