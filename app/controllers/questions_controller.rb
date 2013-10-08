#encoding: utf-8
class QuestionsController < ApplicationController
  before_filter :sign?, :get_round

  def index
    @questions = @round.questions.includes(:knowledge_card).paginate(:per_page => 5, :page => params[:page])
    @branch_question_hash = BranchQuestion.where({:question_id => @questions.map(&:id)}).group_by{|bq| bq.question_id}
    respond_to do |f|
      f.html
      f.js {render :search}
    end
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

  def search
    @questions = @round.questions.where(:types => params[:question_types]).paginate(:per_page => 5, :page => params[:page])
    @branch_question_hash = BranchQuestion.where({:question_id => @questions.map(&:id)}).group_by{|bq| bq.question_id}
  end
  
  private
  def get_round
    @round = Round.find_by_id(params[:round_id])
    @chapter = Chapter.find_by_id(@round.chapter_id) if @round && @round.chapter_id
    @course = Course.find_by_id(@round.course_id) if @round && @round.course_id
  end
end