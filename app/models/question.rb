#encoding: utf-8
class Question < ActiveRecord::Base
  belongs_to :round , :counter_cache => true 
  belongs_to :knowledge_card
  has_many :branch_questions, :dependent => :destroy
  has_many :user_mistake_questions

  TYPES = {0 => "单选题", 1 => "多选题", 2 => "完形填空", 3 => "排序题", 4 => "连线题", 5 => "语音输入题", 6 => "综合题", 7 => "拖拽题", 8 => "填空题"}
  TYPE_NAMES = {:single_choice => 0, :multiple_choice => 1, :fillin => 2, :sortby => 3, :lineup => 4, :voice_input => 5, :zonghe => 6, :drag => 7, :input => 8 }
  
end
