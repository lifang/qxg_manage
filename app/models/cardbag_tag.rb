#encoding: utf-8
class CardbagTag < ActiveRecord::Base
  include Constant
  belongs_to :course
  has_many :card_tag_relations, :dependent => :destroy
  has_many :knowledge_cards, :through => :card_tag_relations

  validates :name, :uniqueness => { :scope => :course_id,
    :message => "同一课程下标签名称已存在！" }
end
