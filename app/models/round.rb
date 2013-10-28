#encoding: utf-8
class Round < ActiveRecord::Base
  belongs_to :chapter, :counter_cache => true
  has_many :questions, :dependent => :destroy
  has_many :round_scores

  STATUS_NAME = { 0 => "未审核", 1 => "已审核"}
  STATUS = {:not_verified => 0, :verified => 1}
  
  STAR = {:three_star =>3, :two_star => 2, :one_star => 1}

  validates :name, uniqueness: { scope: :chapter_id,
    message: "同一章节下关卡名称已存在！" }
  scope :verified, where(:status => STATUS[:verified])
end
