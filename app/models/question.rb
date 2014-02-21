#encoding: utf-8
class Question < ActiveRecord::Base
  include Constant
  belongs_to :round , :counter_cache => true 
  belongs_to :knowledge_card
  has_many :branch_questions, :dependent => :destroy
  has_many :user_mistake_questions
end
