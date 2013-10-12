#encoding: utf-8
class KnowledgeCard < ActiveRecord::Base
  belongs_to :course
  has_many :user_cards_relations
  has_many :card_tag_relations
  has_many :cardbag_tags, :through => :card_tag_relations

  def system_tag
    self.cardbag_tags.joins(:card_tag_relations).where(:types => CardbagTag::TYPE_NAME[:system]).where("card_tag_relations.user_id is null").map(&:name).join("、")
  end
end
