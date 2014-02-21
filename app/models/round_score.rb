class RoundScore < ActiveRecord::Base
  include Constant
  belongs_to :round
  belongs_to :user
  belongs_to :chapter
end
