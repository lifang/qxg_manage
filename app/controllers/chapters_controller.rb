#encoding: utf-8
require 'rubygems'
require 'archive/zip'
class ChaptersController < ApplicationController
  before_filter :sign?
  before_filter :get_course, :except => [:verify]

  def index
    @chapters = @course.chapters
  end

  def new
    @chapter = @course.chapters.new
  end
  
  def create
    @chapter = @course.chapters.create(params[:chapter])
    if @chapter.save
      flash[:notice] = "创建成功！"
      render :success
    else
      @notice = "创建失败！ #{@chapter.errors.messages.values.flatten.join("<br/>")}"
      render :new
    end
  end

  def edit
    @chapter = Chapter.find_by_id(params[:id])
  end

  def update
    @chapter = Chapter.find_by_id(params[:id])
    if @chapter.update_attributes(params[:chapter])
      flash[:notice] = "更新成功！"
      render :success
    else
      @notice = "更新失败！ #{@chapter.errors.messages.values.flatten.join("<br/>")}"
      render :edit
    end
  end



  def destroy
    @chapter = Chapter.find_by_id(params[:id])
    @chapter.destroy
    flash[:notice] = "删除成功"
    redirect_to course_chapters_path(@course.id)
  end

  #审核
  def verify
    @chapter = Chapter.find_by_id params[:id]
    if @chapter.update_attribute(:status, true)
      @notice = "审核成功"
    else
      @notice = "审核失败"
    end
  end

  private
  def get_course
    @course = Course.find_by_id(params[:course_id])
  end

end