class PropsController < ApplicationController
  before_filter :sign?, :get_course

  def index
  end

  
  private
  def get_course
    @course = Course.find_by_id(params[:course_id])
  end
end