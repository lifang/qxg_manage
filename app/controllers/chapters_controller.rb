#encoding: utf-8
require 'rubygems'
require 'archive/zip'
class ChaptersController < ApplicationController
  before_filter :sign?, :get_course

  def index
    @chapters = @course.chapters
  end

  def new
    @chapter = @course.chapters.new
  end
  
  def create
    @chapter = @course.chapters.create(params[:chapter])
    if @chapter.save
      redirect_to course_chapters_path(@course.id)
    else
      render :new
    end
  end

  def edit
    @chapter = Chapter.find_by_id(params[:id])
  end

  def update
    @chapter = Chapter.find_by_id(params[:id])
    if @chapter.update_attributes(params[:chapter])
      redirect_to course_chapters_path(@course.id)
    else
      render :edit
    end
  end

  def uploadfile
    zipfile = params[:zip]

    if !zipfile.nil?
      user_id = 121
      time_now = Time.now().to_s.slice(0,19).gsub(/\:/,'-')

      if !File.directory? "#{Rails.root}/public/qixueguan/tmp/user_#{user_id}"
        Dir.mkdir "#{Rails.root}/public/qixueguan/tmp/user_#{user_id}"
      end

      filename = zipfile.original_filename.split(".")
      zipfile.original_filename = time_now.slice(0,10) + "_" + time_now.slice(11,8) + "." +filename[1]
      File.open(Rails.root.join("public", "qixueguan/tmp/user_#{user_id}", zipfile.original_filename), "wb") do |file|
        file.write(zipfile.read)
      end
      unzip(121, '', '', zipfile.original_filename)
    end
    redirect_to :action => "index"
  end

  def unzip user_id, chapter_id = '', round_id = '', zip_filename
    zip_url = "#{Rails.root}/public/qixueguan/tmp/user_#{user_id}"
    p zip_url
    zip_dir = zip_filename.to_s.split('.')[0]
    p zip_dir
    if !File.directory? "#{zip_url}/#{zip_dir}"
      Dir.mkdir "#{zip_url}/#{zip_dir}"
    end
      Archive::Zip.extract("#{zip_url}/#{zip_filename}","#{zip_url}/#{zip_dir}")
  end

  def destroy
    @chapter = Chapter.find_by_id(params[:id])
    @chapter.destroy
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