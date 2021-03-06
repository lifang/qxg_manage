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
     params[:round][:name] =  name_strip(params[:round][:name])
    if @round.update_attributes(params[:round])
      @round.status = VARIFY_STATUS[:not_verified] if @round.status == VARIFY_STATUS[:verified]
      @round.save
      @notice = "更新成功！"
      render :success
    else
      @notice = "更新失败！\\n #{@round.errors.messages.values.flatten.join("<\\n>")}"
      render :edit
    end
  end

  def destroy
    zip_url = "#{Rails.root}/public/qixueguan/Course_#{params[:course_id]}/Chapter_#{params[:chapter_id]}/Round_#{params[:id]}.zip"
    round_dir = "#{Rails.root}/public/qixueguan/Course_#{params[:course_id]}/Chapter_#{params[:chapter_id]}/Round_#{params[:id]}"
    @round = Round.find_by_id params[:id]
    @round.destroy
    flash[:notice] = "删除成功"
    File.delete zip_url if File.exist? zip_url
    FileUtils.remove_dir round_dir if !round_dir.nil? && Dir.exist?(round_dir)
    redirect_to course_chapter_rounds_path(@course.id,@chapter.id)
  end

  #审核
  def verify
    @round = Round.find_by_id params[:id]
    question_total = @round.questions.count
    if question_total%2 == 0
      question_total = question_total/2
    else
      question_total = (question_total+1)/2
    end

    chapter_id = @round.chapter_id
    course_id =@round.course_id
    one_json_question = []
    questions = @round.questions
    str = ""
    str = str + "course = {\"course_id\" : #{course_id},\n  \"chapter_id\" : #{chapter_id},\n
    \"round_id\" : #{@round.id},\n \"round_time\" : \"#{@round.round_time}\",\n \"question_total\":#{question_total},
      \"round_score\" : #{@round.max_score},  \"percent_time_correct\" : #{@round.time_ratio},\n
    \"blood\" : #{@round.blood},\"questions\" :["
    que = []
    a = 0
    questions.each do |e|
      str = str + "," if a > 0
      branch_questions = e.branch_questions
      branch_que = ""
      c = 0
      branch_questions.each do |x|
        branch_que = branch_que + "," if c > 0
        branch_que =  branch_que + "{\"branch_question_id\":#{x.id}, \"branch_content\":\"#{x.branch_content}\",\"branch_question_types\":#{x.types}, \"options\":\"#{x.options}\",\"answer\":\"#{x.answer}\"}"
        c = c + 1
      end
      knowledge_card = e.knowledge_card
      str = str +  "{\"question_id\":#{e.id},\"content\":\"#{e.content}\",\"question_types\":#{e.types},\"branch_questions\": [#{branch_que}],\"card_id\":#{knowledge_card.try(:id)},\"card_name\": \"#{knowledge_card.try(:name)}\", \"description\": \"#{knowledge_card.try(:description)}\",\"card_types\" : \"#{knowledge_card.try(:types)}\"} \n"
      a = a + 1
    end
    str = str + "]}"
    round_url = "#{Rails.root}/public/qixueguan/Course_#{course_id}/Chapter_#{chapter_id}/Round_#{@round.id}"
    File.delete "#{round_url}/questions.js" if File.exist? "#{round_url}/questions.js"
    File.open("#{round_url}/questions.js", 'wb') do |f|
      f.write(str)
    end
    File.delete "#{round_url}.zip" if File.exist? "#{round_url}.zip"
    Archive::Zip.archive("#{round_url}.zip", round_url)
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
      round_id = nil
      zip_file = params[:file]
      @error_infos =[]

      if zip_file.nil?
        @error_infos << "zip压缩包不存在"
      else
        user_tmp_path = "#{Rails.root}/public/qixueguan/tmp/user_#{user.id}"
        zip_dir = rename_file
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
                  s = check_excel_name excels
                  if s[:status] == 1 #excel命名有问题
                    s[:error_infos].each do |e|
                      @error_infos << e
                    end
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

      if @error_infos.length != 0 #判断错误信息是否为空
        @notice_info = @error_infos
        status = 1
      else #转移文件&插入数据&写入XML文件
        import_data read_excel_result[:all_round_questions], course_id, chapter_id, zip_url, round_id
        status = 0
        @notice_info = ["导入完成！"]
      end
      FileUtils.remove_dir zip_url if !zip_url.nil? && Dir.exist?(zip_url)
      @rounds = Round.where({:course_id => params[:course_id], :chapter_id => params[:chapter_id]}).paginate(:per_page => 16, :page => params[:page])
      @result = {:notice => @notice_info, :status => status}
  end

  private
  def get_course_chapter
    @course = Course.find_by_id params[:course_id]
    @chapter = Chapter.find_by_id params[:chapter_id]
  end
end