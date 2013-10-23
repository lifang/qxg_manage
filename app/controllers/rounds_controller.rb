#encoding: utf-8
require 'json'
class RoundsController < ApplicationController
  before_filter :sign?, :get_course_chapter
  
  def index
    @notice_info = ["sssss","ssss","dddd"]
    @rounds = Round.where({:course_id => params[:course_id], :chapter_id => params[:chapter_id]})
  end

  def edit
    @round = Round.find_by_id params[:id]
  end

  def update
    @round = Round.find_by_id params[:id]
    if @round.update_attributes(params[:round])
      @notice = "更新成功！"
      render :success
    else
      @notice = "更新失败！\\n #{@round.errors.messages.values.flatten.join("<\\n>")}"
      render :edit
    end
  end

  def destroy
    @round = Round.find_by_id params[:id]
    @round.destroy
    flash[:notice] = "删除成功"
    redirect_to course_chapter_rounds_path(@course.id,@chapter.id)
  end

  #审核
  def verify
    @round = Round.find_by_id params[:id]
    if @round.update_attribute(:status, true)
      @notice = "审核成功"
    else
      @notice = "审核失败"
    end
  end

  #导入多个关卡的题库
  def uploadfile
    course_id = params[:course_id]
    chapter_id = params[:chapter_id]
    user_id = User.find_all_by_email(session[:email])[0].id
    zip_file = params[:zip]
    @error_infos = [] #错误信息
    base_url = "#{Rails.root}/public/qixueguan/tmp"
    path = ""
    if !zip_file.nil?
      zip_dir = rename_zip
      p zip_dir
      path = base_url + "/user_#{user_id}/"+ zip_dir
      if upload(base_url, user_id, zip_dir, zip_file) == false
        @error_infos << "上传失败"
      else
        #解压压缩包
        zip_url = "#{base_url}/user_#{user_id}"
        if unzip(zip_url, zip_dir) == false         #解压失败，返回错误提示信息
          @error_infos << "zip压缩包不正确，请上传正确的压缩包"
        else                                        #解压成功，则继续验证
                                                    #excel文件与资源的根目录
          path = "#{zip_url}/#{zip_dir}"

          #获取excel文件数组和资源目录数组
          files_and_dirs = get_file_and_dir path
          excels = files_and_dirs[:excels]
          res_dirs = files_and_dirs[:resource_dirs]

          #获取excel中题目的错误信息
          read_excel_result  = read_excel path, excels

          #p "read_excel_result#{read_excel_result}"
          #p read_excel_result[:all_round_questions]
          #p read_excel_result[:error_infos]
          if read_excel_result[:error_infos].length != 0
            read_excel_result[:error_infos].each do |e|
              @error_infos << e
            end
          end
        end
      end
    else
      @error_infos << "zip压缩包不存在"
    end
    p "@error_info#{@error_infos}"
    @notice_info = ""
                      #判断错误信息是否为空
    if !@error_infos.nil? && @error_infos.length != 0
      @notice_info = @error_infos
    else #转移文件&插入数据&写入XML文件
      import_data read_excel_result[:all_round_questions], course_id, chapter_id, path
      @notice_info =  ["导入完成！"]
    end
  end

  private

  def get_course_chapter
    @course = Course.find_by_id params[:course_id]
    @chapter = Chapter.find_by_id params[:chapter_id]
  end
end