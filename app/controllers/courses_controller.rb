class CoursesController < ApplicationController

  def index
    @courses = Course.all
  end

  def new
    @course = Course.new
  end

  def edit
    @course = Course.find_by_id params[:id]
  end

  def create
    @course = Course.create(params[:course])
    if @course.save
      redirect_to courses_path
    else
      render :new
    end
  end

  def update
    @course = Course.find_by_id params[:id]
    if @course.update_attributes(params[:course])
      redirect_to courses_path
    else
      render :edit
    end
  end
end
