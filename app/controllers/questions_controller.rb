class QuestionsController < ApplicationController
  before_filter :sign?, :get_round

  def index
    @questions = @round.questions.includes(:knowledge_card)
    @branch_question_hash = BranchQuestion.where({:question_id => @questions}).group_by{|bq| bq.question_id}
    
  end

  def destroy
   @question = Question.find_by_id params[:id]
   @question.destroy
   redirect_to round_questions_path(@round)
  end

  def remove_knowledge_card
    @question = Question.find_by_id params[:question_id]
    @question.update_attribute(:knowledge_card_id, nil)
  end
  
  private
  def get_round
    @round = Round.find_by_id(params[:round_id])
    @course = Course.find_by_id(@round.course_id) if @round && @round.course_id
  end
end