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

  #上传文件
  def uploadfile
    zipfile = params[:zip]
    base_url = "#{Rails.root}/public/qixueguan/tmp"
    if !zipfile.nil?
      user_id = 121
      time_now = Time.now().to_s.slice(0,19).gsub(/\:/,'-')
      if !File.directory? "#{base_url}/user_#{user_id}"
        Dir.mkdir "#{base_url}/user_#{user_id}"
      end

      filename = zipfile.original_filename.split(".")
      zip_dir = time_now.slice(0,10) + "_" + time_now.slice(11,8)
      zipfile.original_filename = zip_dir + "." +filename[1]
      File.open(Rails.root.join("public", "qixueguan/tmp/user_#{user_id}", zipfile.original_filename), "wb") do |file|
        file.write(zipfile.read)
      end

      unzip base_url, user_id, zip_dir
      read_excel base_url ,user_id ,zip_dir
      #read_question_data 121, dir, course_id, chapter_id, round_id

    end

    redirect_to :action => "index"
  end

  #解压压缩包、获取excel文件名和资源目录
  def unzip base_url, user_id, zip_dir
    zip_url = "#{base_url}/user_#{user_id}"

    if !File.directory? "#{zip_url}/#{zip_dir}"
      Dir.mkdir "#{zip_url}/#{zip_dir}"
    end
    begin
      Archive::Zip.extract "#{zip_url}/#{zip_dir}.zip","#{zip_url}/#{zip_dir}"
    rescue
    end
    File.delete "#{zip_url}/#{zip_dir}.zip"
  end

  def read_excel base_url ,user_id ,zip_dir
    path = "#{base_url}/user_#{user_id}/#{zip_dir}"
    excel_files =  []
    resource_dir = []

    #获取excel文件和资源目录
    Dir.entries(path).each do |sub|
      if sub != '.' && sub != '..'
        if File.directory?("#{path}/#{sub}")
          resource_dir << sub.to_s
          #get_file_list("#{path}/#{sub}")
        else
          excel_files << sub.to_s
        end
      end
    end

    #循环每个execl文件
    excel_files.each do |excel|
      p "#{path}/#{excel}"
      oo = Roo::Excel.new("#{path}/#{excel}")
      oo.default_sheet = oo.sheets.first
      start_line = 0
      end_line = 0
      #questions = []
      #
      ##确定题目的开始行数
      end_line = oo.last_row
      if end_line  > 0
        1.upto(end_line) do |line|
          every_line = oo.cell(line,'B').to_s
          if every_line.size > 0
            if every_line == "Question" && start_line ==0
              start_line = line+1
              break
            end
          end
        end
      else
        end_line = 0
      end

      count = 1
      start_line.upto(end_line).each do |line|
        p "-----------Question:#{count}------------"
        every_question = oo.cell(line,'B')
        p every_question
        if every_question.scan(/\[\[[^\[\[]*[^\[\]]*\]\]/)
          p every_question.scan(/\[\[[^\[\[]*[^\[\]]*\]\]/)
        end

        p "-----------Question:#{count}------------"
        p ""
        count=count+1
      end


    end

    #resource_dir.each do |dir|
    #  p dir
    #end
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