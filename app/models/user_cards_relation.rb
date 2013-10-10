class UserCardsRelation < ActiveRecord::Base
  belongs_to :knowledge_card
  belongs_to :user
  belongs_to :course
end
