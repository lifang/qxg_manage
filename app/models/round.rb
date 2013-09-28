#encoding: utf-8
class Round < ActiveRecord::Base
  has_many :questions, :dependent => :destroy

  STATUS_NAME = { 0 => "未审核", 1 => "已审核"}

  validates :name, uniqueness: { scope: :chapter_id,
    message: "同一章节下关卡名称已存在！" }
end
