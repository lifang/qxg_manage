#encoding: utf-8
class CardbagTag < ActiveRecord::Base
  belongs_to :course

  TYPES = {0 => "系统", 1 => "用户"}
  TYPE_NAME ={:system => 0, :user => 1}
  scope :system, where(:types => TYPE_NAME[:system])

  validates :name, uniqueness: { scope: :course_id,
    message: "同一课程下标签名称已存在！" }
end
