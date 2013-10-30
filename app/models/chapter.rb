#encoding: utf-8
require 'fileutils'
class Chapter < ActiveRecord::Base

  belongs_to :course, :counter_cache => true
  has_many :rounds
  mount_uploader :img, AvatarUploader
  
  STATUS_NAME = { 0 => "未审核", 1 => "已审核"}
  STATUS = {:not_verified => 0, :verified => 1}

  validates :name, :uniqueness => { :scope => :course_id,
    :message =>  "同一课程下章节名称已存在！" }

  scope :verified, where(:status => STATUS[:verified])
  after_destroy :remove_img
  before_save :set_unverified

  def set_unverified
    self.status = STATUS[:not_verified] if status == STATUS[:verified]
  end
  
  def remove_img
    img_full_path_str = (Rails.root.to_s + "/public" + self.img.url)
    file_dir = File.expand_path("..",img_full_path_str)
    FileUtils.rm_r file_dir if Dir.exists?(file_dir)
  end
end
