#encoding: utf-8
class QuestionsController < ApplicationController
  before_filter :sign?, :get_round

  def index
    @questions = @round.questions.includes(:knowledge_card).paginate(:per_page => 10, :page => params[:page])
    @branch_question_hash = BranchQuestion.where({:question_id => @questions.map(&:id)}).group_by{|bq| bq.question_id}
    respond_to do |f|
      f.html
      f.js {render :search}
    end
  end

  def destroy
   p params
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
      p zip_file
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
        @status = 1
        @notice_info = @error_infos
        @info = {:status => @status, :notice => @notice_info}
    else #转移文件&插入数据&写入XML文件
        questions = Question.where("round_id=#{round_id}")
        if !questions.nil?
          questions.each do |e|
              branch_questions = e.branch_questions
              if e.knowledge_card_id != nil
                knowledge_card = e.knowledge_card
                card_tag_relation = CardTagRelation.find_by_knowledge_card_id_and_user_id(knowledge_card.id,user.id)
                card_tag_relation.destroy #删除和知识卡片的关系
              end
              e.destroy  #删除题目
          end
        end

        import_data read_excel_result[:all_round_questions], course_id, chapter_id, zip_url, user.id
        @status = 0
        @notice_info = "导入完成！"
        @round = Round.find(round_id)
        @questions = @round.questions.includes(:knowledge_card).paginate(:per_page => 10, :page => 1)
        @branch_question_hash = BranchQuestion.where({:question_id => @questions.map(&:id)}).group_by{|bq| bq.question_id}
        @info = {:status => @status, :notice => @notice_info, :question => @questions, :branch_question => @branch_question_hash}
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

  #展示原题
  def view
    @question = Question.find(params[:id])
  end

  #编辑题目
  def edit
    error_infos = []
    full_text = params[:question][:full_text]
    question_id = params[:id]
    origin_types = params[:types].to_i
    round_id = params[:round_id]

    if brackets_validate(full_text) == 1
      error_infos << "该题双括号配对不完整、双括号存在嵌套或存在两个以上的连续括号"
    else
      type = -1
      error_info = ""

      #判断题型,题目信息错误验证
      result = distinguish_question_types excel="",full_text,line=""
      type = result[:que_tpye]
      if origin_types != type
        error_infos << "与原题题型不符，只能编辑题目内容，不能改变题型！"
      end
      #p "result#{result}"
      error_info = result[:error_info]

      error_infos << error_info if !error_info.empty?
    end
    p origin_types
    p type

    if error_infos.length == 0 && type != -1
      #删除原有小题
      que = Question.find(question_id)
      que.branch_questions.each do |e|
        e.destroy
      end

      que_hash = split_question full_text,type #截取题目

      #更新大题,新建小题
      que.update_attributes(:content => que_hash[:content], :full_text => full_text)
      que_hash[:branch_questions].each do |e|
        que.branch_questions.create(:branch_content => e[:branch_content], :types => e[:branch_question_types],
        :options => e[:options], :answer => e[:answer])
      end
      @questions = @round.questions.includes(:knowledge_card).paginate(:per_page => 10, :page => params[:page])
      @branch_question_hash = BranchQuestion.where({:question_id => @questions.map(&:id)}).group_by{|bq| bq.question_id}
      round = Round.find(round_id)
      round.update_attributes(:status => Round::STATUS[:not_verified])
      @info = {:status => 0 , :notice => "编辑完成！", :question => @questions, :branch_question => @branch_question_hash}
    else
      @info = {:status => -1, :notice => error_infos}
    end
  end
  
  private
  def get_round
    @round = Round.find_by_id(params[:round_id])
    @chapter = Chapter.find_by_id(@round.chapter_id) if @round && @round.chapter_id
    @course = Course.find_by_id(@round.course_id) if @round && @round.course_id
  end
end