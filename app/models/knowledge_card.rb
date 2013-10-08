class KnowledgeCard < ActiveRecord::Base
  belongs_to :course
  has_many :user_cards_relations
end
