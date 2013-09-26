#encoding: utf-8
require 'fileutils'
class Chapter < ActiveRecord::Base
  belongs_to :course
  has_many :rounds
  mount_uploader :img, AvatarUploader
  
  STATUS_NAME = { 0 => "未审核", 1 => "已审核"}

  after_destroy :remove_img
  def remove_img
    img_full_path_str = (Rails.root.to_s + "/public" + self.img.url)
    file_dir = File.expand_path("..",img_full_path_str)
    FileUtils.rm_r file_dir if Dir.exists?(file_dir)
  end
end
