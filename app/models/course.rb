class Course < ActiveRecord::Base
  has_many :knowledge_cards
  has_many :chapters, :dependent => :destroy
  has_many :rounds, :dependent => :destroy
end
