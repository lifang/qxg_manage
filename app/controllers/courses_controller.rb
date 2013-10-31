#encoding: utf-8
class CoursesController < ApplicationController
  before_filter :sign?
  def index
    @courses = Course.paginate(:per_page =>9, :page => params[:page])
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
      @notice = "添加成功！"
      render :success
    else
       @notice = "添加失败！\\n #{@course.errors.messages.values.flatten.join("<\\n>")}"
      render :new
    end
  end

  def update
    @course = Course.find_by_id params[:id]
    if @course.update_attributes(params[:course])
      @course.status = Course::STATUS[:not_verified] if @course.status == Course::STATUS[:verified]
      @course.save
      @notice = "更新成功！"
      render :success
    else
      @notice = "更新失败！\\n #{@course.errors.messages.values.flatten.join("<\\n>")}"
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
