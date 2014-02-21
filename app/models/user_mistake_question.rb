class UserMistakeQuestion < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
  belongs_to :question
end
