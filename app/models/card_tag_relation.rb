class CardTagRelation < ActiveRecord::Base
  belongs_to :knowledge_card
  belongs_to :user
  belongs_to :course
  belongs_to :cardbag_tag
end