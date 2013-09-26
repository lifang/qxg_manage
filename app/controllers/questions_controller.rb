class QuestionsController < ApplicationController
  before_filter :sign?, :get_round

  def index
    @questions = @round.questions
  end

  
  private
  def get_round
    @round = Round.find_by_id(params[:round_id])
  end
end