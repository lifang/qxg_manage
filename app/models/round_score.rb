class RoundScore < ActiveRecord::Base
  belongs_to :round
  belongs_to :user
  belongs_to :chapter
end
