#encoding: utf-8
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
    p "course_id#{course_id},chapter_id#{chapter_id}"

    if !zip_file.nil?
      zip_dir = rename_zip
      p zip_dir
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
          res_dir = files_and_dirs[:resource_dirs]
          #验证资源目录和excel
          #number = "one" #验证的控制参数：单个关卡导入参数为“one”，多个关卡导入参数为“more”
          #result = validate_file_and_dir files_and_dirs,number
          #if result.length != 0
          #  result.each do  |e|
          #    @error_infos << e.to_s
          #  end
          #else
          #获取excel中题目的错误信息
          read_excel_result  = read_excel path, excels

          #p "read_excel_result#{read_excel_result}"
          #p read_excel_result[:all_round_questions]
          if read_excel_result[:error_infos].length != 0
            read_excel_result[:error_infos].each do |e|
              @error_infos << e
            end
          end
                                                    #end
        end
      end
    else
      @error_infos << "zip压缩包不存在"
    end
    p @error_infos
    @notice_info = ""
                      #判断错误信息是否为空
    if !@error_infos.nil? && @error_infos.length != 0
      @notice_info = @error_infos
    else #转移文件&插入数据&写入XML文件
      import_data read_excel_result[:all_round_questions], course_id, chapter_id
      @notice_info =  ["导入完成！"]
    end
  end

  ##导入题库          20131020 19：05
  #def uploadfile
  #  course_id = params[:course_id]
  #  chapter_id = params[:chapter_id]
  #  user_id = User.find_all_by_email(session[:email])[0].id
  #  zip_file = params[:zip]
  #  base_url = "#{Rails.root}/public/qixueguan/tmp"
  #  @error_infos = [] #存放错误信息
  #
  #  if !zip_file.nil?
  #      time_now = Time.now().to_s.slice(0,19).gsub(/\:/,'-')
  #      zip_dir = time_now.slice(0,10) + "_" + time_now.slice(11,8)
  #      upload base_url, user_id, zip_dir, zip_file
  #
  #      #解压压缩包
  #      zip_url = "#{base_url}/user_#{user_id}"
  #      if unzip(zip_url, zip_dir) == false         #解压失败，返回错误提示信息
  #         @error_infos << "zip压缩包不正确，请上传正确的压缩包"
  #      else                                        #解压成功，则继续验证
  #          #excel文件与资源的根目录
  #          path = "#{zip_url}/#{zip_dir}"
  #
  #          #获取excel文件数组和资源目录数组
  #          all_files = get_file_and_dir path
  #          p all_files
  #          if all_files[:excels].length != 0
  #            p all_files[:excels]
  #          else
  #            @error_infos << "没有excel文件"
  #          end
  #          #获取excel中题目的错误信息
  #          @error_infos = read_excel path,all_files[:excels]
  #      end
  #  else
  #      @error_infos << "zip压缩包不存在"
  #  end
  #
  #  @notice_info = ""
  #  #判断错误信息是否为空
  #  if !@error_infos.nil? && @error_infos.length != 0
  #    @notice_info = @error_infos
  #  else #转移文件&插入数据&写入XML文件
  #    @notice_info =  ["导入完成！"]
  #  end
  #end

  private

  def get_course_chapter
    @course = Course.find_by_id params[:course_id]
    @chapter = Chapter.find_by_id params[:chapter_id]
  end
end