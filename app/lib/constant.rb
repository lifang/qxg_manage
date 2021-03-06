#encoding: utf-8
module Constant
  #已审核，未审核。源自course.rb, chapter.rb, round.rb
  VERIFY_STATUS_NAME = { 0 => "未审核", 1 => "已审核"}
  VARIFY_STATUS = {:not_verified => 0, :verified => 1}

  #课程类别
  COURSE_TYPES = {0 => "英语四级", 1 => "英语六级", 2 => "托福口语", 3 => "雅思", 4 => "JAVA",
    5 => "Android", 6 => "Cocos2d-x", 7 => "计算机"}

  #道具，购买 还是使用。源自buy_record.rb
  PROP_TYPES = {0 => "购买", 1 => "使用"}
  PROP_TYPE_NAME = {:buy => 0, :use => 1}

  #知识卡片标签，是系统添加还是用户添加。源自cardbag_tag.rb
  TAG_TYPES = {0 => "系统", 1 => "用户"}
  TAG_TYPE_NAME ={:system => 0, :user => 1}

  #每日任务答题，默认血量，默认题目数量
  BLOOD = 5
  QUESTION_COUNT = 20
  CARD_BAG_DEFAULT = 25

  #道具状态，答题前中后，源自prop.rb
  PROP_STATUS = {0 => "正常", 1 => "删除"}
  PROP_STATUS_NAME = {:normal => 0, :delete => 1}
  PROP_QUESTION_TYPES = {0 => "答题前", 1 => "答题中", 2 => "答题后"}
  #时光卡，财富卡，去错卡，医疗卡，作弊卡，换题卡，经验卡 @道具作用
  PROP_FUNCTION_TYPES = {:time => 0, :asset => 1, :remove_wrong => 2, :medical => 3, :cheat => 4, :exchange => 5, :experience => 6}
  PROP_FUNCTION_TYPES_NAME = {0 => "时光卡", 1 => "财富卡", 2 => "去错卡", 3 => "医疗卡", 4 => "作弊卡", 5 => "换题卡", 6 => "经验卡"}

  #题目类型，源自question,rb
  QUESTION_TYPES = {0 => "单选题", 1 => "多选题", 2 => "完形填空", 3 => "排序题", 4 => "连线题", 5 => "语音输入题", 6 => "综合题", 7 => "拖拽题", 8 => "填空题"}
  QUESTION_TYPE_NAMES = {:single_choice => 0, :multiple_choice => 1, :fillin => 2, :sortby => 3, :lineup => 4, :voice_input => 5, :zonghe => 6, :drag => 7, :input => 8 }

  #关卡星级
  ROUND_STAR = {:three_star =>3, :two_star => 2, :one_star => 1}

  #user mode, 源自user.rb
  USER_TYPES = {:ADMIN => 0, :NORMAL => 1}  #用户类型

end