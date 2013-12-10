#encoding: utf-8
class Course < ActiveRecord::Base
  include ImageHandler
  include Constant
  
  has_many :knowledge_cards
  has_many :chapters, :dependent => :destroy
  has_many :rounds, :dependent => :destroy
  has_many :cardbag_tags, :dependent => :destroy
  has_many :props, :dependent => :destroy
  has_many :user_course_relations
  has_many :courses, :through => :user_course_relations
  mount_uploader :img, AvatarUploader
  attr_accessor :type_name

  validates :name, :uniqueness => { :message =>  "课程名称已存在！" }

  scope :verified, where(:status => VARIFY_STATUS[:verified])
  
  after_destroy :remove_image_after_deleted
end
