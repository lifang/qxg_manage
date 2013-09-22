class Course < ActiveRecord::Base
  has_many :knowledge_cards
end
