#encoding: utf-8
class Round < ActiveRecord::Base
  has_many :questions, :dependent => :destroy

  STATUS_NAME = { 0 => "未审核", 1 => "已审核"}
end
