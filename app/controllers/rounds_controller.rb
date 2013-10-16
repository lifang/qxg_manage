#encoding: utf-8
class RoundsController < ApplicationController
  before_filter :sign?, :get_course_chapter
  
  def index
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

  #上传文件
  def uploadfile
    course_id = params[:course_id]
    chapter_id = params[:chapter_id]
    user_id = User.find_all_by_email(session[:email])[0].id
    zipfile = params[:zip]
    base_url = "#{Rails.root}/public/qixueguan/tmp"
    @error_infos = [] #存放错误信息

    if !zipfile.nil?
        time_now = Time.now().to_s.slice(0,19).gsub(/\:/,'-')
        if !File.directory? "#{base_url}/user_#{user_id}"
          Dir.mkdir "#{base_url}/user_#{user_id}"
        end

        #重命名zip压缩包为“年-月-日_时-分-秒”
        zip_dir = time_now.slice(0,10) + "_" + time_now.slice(11,8)
        zipfile.original_filename = zip_dir + "." +  zipfile.original_filename.split(".").to_a[1]

        #上传文件
        File.open(Rails.root.join("public", "qixueguan/tmp/user_#{user_id}", zipfile.original_filename), "wb") do |file|
          file.write(zipfile.read)
        end

        #解压压缩包
        zip_url = "#{base_url}/user_#{user_id}"
        if unzip(zip_url, zip_dir) == false
           @error_infos << "zip压缩包不正确，请上传正确的压缩包"
        else
            #excel文件与资源的根目录
            path = "#{base_url}/user_#{user_id}/#{zip_dir}"

            #获取excel文件数组和资源目录数组
            all_files = get_file_and_dir path
            p all_files
            if all_files
            end
            #获取excel中题目的错误信息
            @error_infos = read_excel path,all_files[:excels]
        end #if unzip(zip_url, zip_dir) == false
    else
        @error_infos << "zip压缩包不存在"
    end #if !zipfile.nil?

    #判断错误信息是否为空
    if !@error_infos.nil? && @error_infos.length != 0
      @notice = @error_infos
    else #转移文件&插入数据&写入XML文件
      @notice = "导入完成！"
    end #if !@error_infos.nil? && @error_infos.length != 0
  end



  #读取excel信息
  def read_excel path, excel_files
    error_infos = [] #错误信息的集合
    questions = [] #单个关卡所有题目的集合
    #p excel_files
    #循环每个execl文件
    excel_files.each do |excel|
      #p "#{path}/#{excel}"
      begin
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
            str = oo.cell(line,'A').to_s
            if str.size > 0
              if str == "Question" && start_line ==0
                start_line = line+1
                break
              end
            end
          end
        else
          end_line = 0
        end

        #循环取出每一题
        start_line.upto(end_line).each do |line|
          que = oo.cell(line,'A').to_s
          type = -1
          error_info = ""
          #判断题型
          result = distinguish_question_types excel,que,line
          result.each do |key,val|
            if val.class == Fixnum
              type = val
            else
              error_info = val[0].to_s
            end
          end
          error_infos << error_info if !error_info.empty?

          if error_infos.length == 0 && type != -1
            questions << split_question(que,type)
          end
        end
      rescue
        error_infos << "#{excel}不是Excel文件"
        excel_files.delete(excel)
        #p excel_files
        read_excel path,excel_files
      end
    end
    #resource_dir.each do |dir|
    #  p dir
    #
    questions.each do |e|
      p e
    end
    error_infos if error_infos.length != 0
  end



  #处理题目中的大题，小题与选项
  def split_question que, type
    p Question::TYPES[type]
    question = {} #大题的哈希
    content = "" #大题题面
    question_types = type #大题类型
    branch_questions = [] #小题数组
    branch_content = "" #小题内容
    branch_question_types = -1 #小题类型
    options = "" #选项
    answer = ""  #答案
    card_name = "" #知识卡片名称
    description = "" #知识卡片描述
    card_types = "" #知识卡片标签


    if type == Question::TYPE_NAMES[:single_choice]          #单选题
      branch_question_types = type
      options = que.scan(/\[\[[^\[\[]*\]\]/)[0].to_s.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s.gsub(/\|\|/,";||;")
      options.split(";||;").each do |e|
        if e.to_s.match(/^@@.*/)
          answer = e.to_s.scan(/[^\@\@].*/)[0].to_s
        end
      end
      options = options.gsub(/@@/,"").gsub(/^;\|\|;/,"").gsub(/;\|\|;$/,"")
      content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]")
      branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
      :options => options, :answer => answer}
    elsif type == Question::TYPE_NAMES[:multiple_choice]   #多选题
      branch_question_types = type
      options = que.scan(/\[\[[^\[\[]*\]\]/)[0].to_s.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s.gsub(/\|\|/,";||;")
      c = 0
      options.split(";||;").each do |e|
        if e.match(/^\@\@.*/)
          if c != 0
            answer = answer +";||;"
          end
          answer = answer + e.gsub(/\@\@/,"")
          c = c + 1
        end
      end
      options = options.gsub(/@@/,"").gsub(/^;\|\|;/,"").gsub(/;\|\|;$/,"")
      content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]")
      branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
                         :options => options, :answer => answer}
    elsif type == Question::TYPE_NAMES[:fillin]   #完型填空题
      branch_question_types = type
      all_answers = []
      all_options = []
      result = que.scan(/\[\[[^\[\[]*\]\]/)
      result.each do |e|
        e = e.scan(/(?<=\[\[).*(?=\]\])/)[0].to_s.gsub(/\|\|/,";||;")
        e.split(";||;").to_a.each do |x|
          if x.lstrip.match(/^@@.+/)
            all_answers << x.gsub(/^@@/,"").to_s
          end
        end
        all_options <<  e.gsub(/@@/,"")
      end

      if all_answers.length == all_options.length
        length = all_answers.length.to_i - 1
        (0..length).each do |i|
          options = all_options[i]
          answer = all_answers[i]
          branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
                               :options => options, :answer => answer}
        end
      end
      content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]")
    elsif type == Question::TYPE_NAMES[:sortby]   #排序题
      branch_question_types = type
      options = que.scan(/\[\[[^\[\[]*\]\]/)[0].to_s.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s.gsub(/\;\;/,";||;").gsub(/;\|\|;$/,"")
      answer =options
      content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]")
      branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
                           :options => options, :answer => answer}
    elsif type == Question::TYPE_NAMES[:lineup]   #连线题
      branch_question_types = type
      options = que.scan(/\[\[[^\[\[]*\]\]/)[0].to_s.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s.gsub(/\|\|/,";||;").gsub(/file>>>/,"file>;=;").gsub(/>>/,";=;")
      p options
      answer =options
      content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]")
      branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
                           :options => options, :answer => answer}
    elsif type == Question::TYPE_NAMES[:voice_input]  #语音输入题
      branch_question_types = type
      options = que.scan(/\{\{[^\{\{]*\}\}/)[0].to_s.scan(/(?<=\{\{).*(?=\}\})/).to_a[0]
      answer =options
      content = que.gsub(/\{\{[^\{\{]*\}\}/,"[[text]]")
      branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
                           :options => options, :answer => answer}
    elsif type == Question::TYPE_NAMES[:read_understanding] #综合题
      branch_question_types = type
      options = que.scan(/\{\{[^\{\{]*\}\}/)[0].to_s.scan(/(?<=\{\{).*(?=\}\})/).to_a[0]
    elsif type == Question::TYPE_NAMES[:drag]     #拖拽题
      branch_question_types = type
      c = 0
      que.scan(/\[\[[^\[\[]*\]\]/).to_a.each  do  |e|
        e = e.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s
        p e
        if c > 0
          options = options + ";||;"
        end
        options = options + e
        c = c +1
      end
      answer = options
      content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]")
      branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
                           :options => options, :answer => answer}
    elsif type == Question::TYPE_NAMES[:input]    #填空题
      branch_question_types = type
      c = 0
      que.scan(/\(\([^\(\(]*\)\)/).to_a.each  do  |e|
        e = e.scan(/(?<=\(\().*(?=\)\))/).to_a[0].to_s
        p e
        if c > 0
          options = options + ";||;"
        end
        options = options + e
        c = c +1
      end
      answer = options
      content = que.gsub(/\(\([^\(\(]*\)\)/,"[[text]]")
      branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
                           :options => options, :answer => answer}
    end
    question = {:content => content, :question_types => question_types, :branch_questions => branch_questions}
  end

  private

  def get_course_chapter
    @course = Course.find_by_id params[:course_id]
    @chapter = Chapter.find_by_id params[:chapter_id]
  end
end