#encoding: utf-8
class CardbagTagsController < ApplicationController
  before_filter :sign?, :get_course

  def index
    @tags = @course.cardbag_tags
  end

  def new
    @tag = CardbagTag.new
  end

  def create
    @tag = @course.cardbag_tags.create(params[:cardbag_tag])
    if @tag.save
      redirect_to course_cardbag_tags_path(@course.id)
    else
      render :new
    end
  end

  def edit
   @tag = CardbagTag.find_by_id(params[:id])
  end

  def update
    @tag = CardbagTag.find_by_id(params[:id])
    if @tag.update_attributes(params[:cardbag_tag])
      redirect_to course_cardbag_tags_path(@course.id)
    else
      render :edit
    end
  end

  def destroy
    @tag = CardbagTag.find_by_id(params[:id])
    @tag.destroy
  end
 
  private
  def get_course
    @course = Course.find_by_id(params[:course_id])
  end

end