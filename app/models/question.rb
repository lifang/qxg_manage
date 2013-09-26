#encoding: utf-8
class Question < ActiveRecord::Base
  belongs_to :round
  has_many :branch_questions, :dependent => :destroy

  TYPES = {0 => "单选", 1 => "多选", 2 => "完形填空", 3 => "排序题", 4 => "连线题", 5 => "语音输入题"}
end
