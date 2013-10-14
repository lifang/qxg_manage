#encoding: utf-8
class CoursesController < ApplicationController
  before_filter :sign?
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
      @notice = "更新成功！"
      render :success
    else
      @notice = "更新失败！ #{@course.errors.messages.values.flatten.join("<br/>")}"
      render :edit
    end
  end
  #TODO
  def destroy
    @course = Course.find_by_id params[:id]
    @course.destroy
    flash[:notice] = "删除成功"
    redirect_to courses_path
  end

  #审核
  def verify
    @course = Course.find_by_id params[:id]
    if @course.update_attribute(:status, true)
      @notice = "审核成功"
    else
      @notice = "审核失败"
    end
  end
end
