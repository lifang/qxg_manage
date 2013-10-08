#encoding: utf-8
class Question < ActiveRecord::Base
  belongs_to :round
  belongs_to :knowledge_card
  has_many :branch_questions, :dependent => :destroy

  TYPES = {0 => "单选题", 1 => "多选题", 2 => "完形填空", 3 => "排序题", 4 => "连线题", 5 => "语音输入题", 6 => "阅读理解"}
  TYPE_NAMES = {"single_choice" => 0, "multiple_choice" => 1, "fillin" => 2, "sortby" => 3, "lineup" => 4, "voice_input" => 5, "read_understanding" => 6}
  
end
