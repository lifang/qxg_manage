class QuestionsController < ApplicationController
  before_filter :sign?, :get_round

  def index
    @questions = @round.questions.includes(:knowledge_card)
    @branch_question_hash = BranchQuestion.where({:question_id => @questions}).group_by{|bq| bq.question_id}
    
  end

  
  private
  def get_round
    @round = Round.find_by_id(params[:round_id])
    @course = Course.find_by_id(@round.course_id) if @round && @round.course_id
  end
end