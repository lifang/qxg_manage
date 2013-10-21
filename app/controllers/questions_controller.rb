#encoding: utf-8
class QuestionsController < ApplicationController
  before_filter :sign?, :get_round

  def index
    @questions = @round.questions.includes(:knowledge_card).paginate(:per_page => 5, :page => params[:page])
    @branch_question_hash = BranchQuestion.where({:question_id => @questions.map(&:id)}).group_by{|bq| bq.question_id}
    respond_to do |f|
      f.html
      f.js {render :search}
    end
  end

  def destroy
   @question = Question.find_by_id params[:id]
   @question.destroy
   redirect_to round_questions_path(@round)
  end

  #导入一个关卡的题库
  def uploadfile
    course_id = params[:course_id]
    chapter_id = params[:chapter_id]
    round_id = params[:round_id]
    user_id = User.find_all_by_email(session[:email])[0].id
    zip_file = params[:zip]
    @error_infos = [] #错误信息
    base_url = "#{Rails.root}/public/qixueguan/tmp"
    p "course_id#{course_id},chapter_id#{chapter_id},round_id#{round_id}"

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
          number = "one" #验证的控制参数：单个关卡导入参数为“one”，多个关卡导入参数为“more”
          result = validate_file_and_dir files_and_dirs,number
          if result.length != 0
            result.each do  |e|
              @error_infos << e.to_s
            end
          else
            #获取excel中题目的错误信息
            read_excel_result  = read_excel path, excels
            p "read_excel_result#{read_excel_result}"
            #p read_excel_result[:all_round_questions]
            if read_excel_result[:error_infos].length != 0
              read_excel_result[:error_infos].each do |e|
                p e
              end
            end
          end
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
      @notice_info =  ["导入完成！"]
    end
  end

  def remove_knowledge_card
    @question = Question.find_by_id params[:question_id]
    @question.update_attribute(:knowledge_card_id, nil)
  end

  def search
    @questions = @round.questions.where(:types => params[:question_types]).paginate(:per_page => 5, :page => params[:page])
    @branch_question_hash = BranchQuestion.where({:question_id => @questions.map(&:id)}).group_by{|bq| bq.question_id}
  end
  
  private
  def get_round
    @round = Round.find_by_id(params[:round_id])
    @chapter = Chapter.find_by_id(@round.chapter_id) if @round && @round.chapter_id
    @course = Course.find_by_id(@round.course_id) if @round && @round.course_id
  end
end