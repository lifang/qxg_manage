class KnowledgeCardsController < ApplicationController
  before_filter :sign?, :get_course

  def index
    
  end

  def show
#    @knowledga_card = KnowledgeCard.find_by_id(params[:id])
#    @question_id = params[:question_id]
  end

  
  private
  def get_course
    @course = Course.find_by_id(params[:course_id])
  end
  
end