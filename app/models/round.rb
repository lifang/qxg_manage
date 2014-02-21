#encoding: utf-8
class Round < ActiveRecord::Base
  include Constant
  belongs_to :chapter, :counter_cache => true
  has_many :questions, :dependent => :destroy
  has_many :round_scores, :dependent => :destroy

  # validates :name, :uniqueness => { :scope => :chapter_id,
  #   :message => "同一章节下关卡名称已存在！" }
  scope :verified, where(:status => VARIFY_STATUS[:verified])
end
