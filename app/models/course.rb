#encoding: utf-8
class Course < ActiveRecord::Base
  include ImageHandler
  
  has_many :knowledge_cards
  has_many :chapters, :dependent => :destroy
  has_many :rounds, :dependent => :destroy
  has_many :cardbag_tags, :dependent => :destroy
  has_many :props, :dependent => :destroy
  has_many :user_course_relations
  has_many :courses, :through => :user_course_relations
  mount_uploader :img, AvatarUploader
  attr_accessor :type_name

  TYPES = {0 => "英语四级", 1 => "英语六级", 2 => "托福口语", 3 => "雅思", 4 => "JAVA",
    5 => "Android", 6 => "Cocos2d-x", 7 => "计算机"}
  STATUS_NAME = { 0 => "未审核", 1 => "已审核"}
  STATUS = {:not_verified => 0, :verified => 1}
  validates :name, :uniqueness => { :message =>  "课程名称已存在！" }

  scope :verified, where(:status => STATUS[:verified])
  
  after_destroy :remove_image_after_deleted
end
