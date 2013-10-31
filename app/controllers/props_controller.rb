#encoding: utf-8
class PropsController < ApplicationController
  before_filter :sign?, :get_course

  def index
    @props = @course.props
  end

  def new
    @prop = Prop.new
  end

  def create
    params[:prop][:name] =  name_strip(params[:prop][:name])
    params[:prop][:question_types] = params[:prop][:question_types].join(",")
    @prop = @course.props.create(params[:prop])
    if @prop.save
      @notice = "添加成功!"
      render :success
    else
      @notice = "添加失败！ #{@prop.errors.messages.values.flatten.join("<br/>")}"
      render :new
    end
  end

  def edit
    @prop = Prop.find_by_id(params[:id])
  end

  def update
    params[:prop][:name] =  name_strip(params[:prop][:name])
    params[:prop][:question_types] = params[:prop][:question_types].join(",")
    @prop = Prop.find_by_id(params[:id])
    if @prop.update_attributes(params[:prop])
      @notice = "更新成功!"
      render :success
    else
      @notice = "更新失败！ #{@prop.errors.messages.values.flatten.join("<br/>")}"
      render :edit
    end
  end

  def destroy#假删，更改状态为1
    @prop = Prop.find_by_id(params[:id])
    @prop.update_attribute(:status, 1)
    flash[:notice] = "删除成功"
    redirect_to course_props_path(@course.id)
  end
  
  private
  def get_course
    @course = Course.find_by_id(params[:course_id])
  end
end