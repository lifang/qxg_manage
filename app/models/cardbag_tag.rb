#encoding: utf-8
class CardbagTag < ActiveRecord::Base
  belongs_to :course

  validates :name, uniqueness: { scope: :course_id,
    message: "同一课程下标签名称已存在！" }
end
