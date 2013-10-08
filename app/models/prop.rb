#encoding: utf-8
class Prop < ActiveRecord::Base
  belongs_to :course
  mount_uploader :img, AvatarUploader

  STATUS = {0 => "正常", 1 => "删除"}
  STATUS_NAME = {:normal => 0, :delete => 1}
  TYPES = {0 => "答题前", 1 => "答题中", 2 => "答题后"}

  validates :name, uniqueness: { scope: :course_id,
    message: "同一课程下道具名称已存在！" }
end
