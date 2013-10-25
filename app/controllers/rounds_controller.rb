#encoding: utf-8
require 'json'
class RoundsController < ApplicationController
  before_filter :sign?, :get_course_chapter
  
  def index
    @rounds = Round.where({:course_id => params[:course_id], :chapter_id => params[:chapter_id]}).paginate(:per_page => 16, :page => params[:page])
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

  #导入多个关卡
  def uploadfile
      course_id = params[:course_id]
      chapter_id = params[:chapter_id]
      user = User.find_by_email(session[:email])
      zip_file = params[:file]
      @error_infos =[]

      if zip_file.nil?
        @error_infos << "zip压缩包不存在"
      else
        user_tmp_path = "#{Rails.root}/public/qixueguan/tmp/user_#{user.id}"
        zip_dir = rename_zip
        if upload(user_tmp_path,zip_dir,zip_file)== false  #上传文件
            @error_infos << "上传失败"
        else
          zip_url = "#{user_tmp_path}/#{zip_dir}"
          if unzip(zip_url) == false         #解压zip压缩包
              @error_infos << "zip压缩包不正确，请上传正确的压缩包"
          else
              #获取excel文件数组和资源目录数组
              excels_and_dirs = get_excels_and_dirs zip_url
              excels = excels_and_dirs[:excels]
              resource_dirs = excels_and_dirs[:dirs]
              if excels.length <= 0
                  @error_infos << "没有找到excel题目文件"
              else
                  #获取excel中题目的错误信息
                  read_excel_result  = read_excel zip_url, excels
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
        end
      end

      if @error_infos.length != 0 #判断错误信息是否为空
        @notice_info = @error_infos
      else #转移文件&插入数据&写入XML文件
        import_data read_excel_result[:all_round_questions], course_id, chapter_id, zip_url
        @notice_info = "导入完成！"
      end
  end

  private

  def get_course_chapter
    @course = Course.find_by_id params[:course_id]
    @chapter = Chapter.find_by_id params[:chapter_id]
  end
end