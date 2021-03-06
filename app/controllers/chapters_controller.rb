#encoding: utf-8
require 'rubygems'
require 'archive/zip'
class ChaptersController < ApplicationController
  before_filter :sign?
  before_filter :get_course, :except => [:verify]

  def index
    @chapters = @course.chapters.paginate(:per_page =>9, :page => params[:page])
  end

  def new
    @chapter = @course.chapters.new
  end
  
  def create
    params[:chapter][:name] =  name_strip(params[:chapter][:name])
    @chapter = @course.chapters.create(params[:chapter])
    if @chapter.save
      flash[:notice] = "添加成功！"
      render :success
    else
      @notice = "添加失败！\\n #{@chapter.errors.messages.values.flatten.join("\\n")}"
      render :new
    end
  end

  def edit
    @chapter = Chapter.find_by_id(params[:id])
  end

  def update
    @chapter = Chapter.find_by_id(params[:id])
    params[:chapter][:name] =  name_strip(params[:chapter][:name])
    if @chapter.update_attributes(params[:chapter])
      @chapter.status = VARIFY_STATUS[:not_verified] if @chapter.status == VARIFY_STATUS[:verified]
      @chapter.save
      flash[:notice] = "更新成功！"
      render :success
    else
      @notice = "更新失败！\\n #{@chapter.errors.messages.values.flatten.join("\\n")}"
      render :edit
    end
  end



  def destroy
    @chapter = Chapter.find_by_id(params[:id])
    chapter_url = "#{Rails.root}/public/qixueguan/Course_#{@chapter.course_id}/Chapter_#{@chapter.id}"
    FileUtils.remove_dir chapter_url if Dir.exist? chapter_url
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