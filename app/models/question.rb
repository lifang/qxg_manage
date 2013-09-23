class Question < ActiveRecord::Base
  belongs_to :round
  has_many :branch_questions, :dependent => :destroy
end
