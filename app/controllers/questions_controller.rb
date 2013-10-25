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

  def delete

  end

  def destroy
   @question = Question.find_by_id params[:id]
   @question.destroy
   redirect_to round_questions_path(@round)
  end

  #导入多个关卡
  def uploadfile
    course_id = params[:course_id].to_i
    chapter_id = params[:chapter_id].to_i
    round_id = params[:round_id].to_i
    user = User.find_by_email(session[:email])
    zip_file = params[:file]
    zip_url = ""
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
             #FileUtils.remove_dir zip_url
          elsif excels.length > 1
             @error_infos << "只能导入一个关卡的题目"
             #FileUtils.remove_dir zip_url
          else
             begin
                oo = Roo::Excel.new("#{zip_url}/#{excels[0]}")
                oo.default_sheet = oo.sheets.first
             rescue
                @error_infos << "#{excels[0]}不是excel文件，请重新导入"
                #FileUtils.remove_dir zip_url
             end
             round_name = oo.cell(2,'A').to_s.strip
             if round_name.size > 0
                round = Round.find_by_name_and_chapter_id_and_course_id(round_name,chapter_id,course_id)
                if round.nil? || (round.id != round_id)
                   @error_infos << "该excel题目文件不属于该关卡，请重新导入"
                   #FileUtils.remove_dir zip_url
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
      end
    end

    if @error_infos.length != 0 #判断错误信息是否为空
        #FileUtils.remove_dir(zip_url)
        @notice_info = @error_infos
    else #转移文件&插入数据&写入XML文件
        import_data read_excel_result[:all_round_questions], course_id, chapter_id, zip_url
        @notice_info = "导入完成！"
    end
    FileUtils.remove_dir zip_url if Dir.exist? zip_url
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