#encoding: utf-8
class RoundsController < ApplicationController
  before_filter :sign?, :get_course_chapter
  
  def index
    @rounds = Round.where({:course_id => params[:course_id], :chapter_id => params[:chapter_id]})
  end

  # no need
  def new
    @round = Round.new
  end
  # no need
  def create
    @round = @chapter.rounds.create(params[:round].merge({:course_id => @course.id}))
    if @round.save
      redirect_to course_chapter_rounds_path(@course.id,@chapter.id)
    else
      render :new
    end
  end

  def edit
    @round = Round.find_by_id params[:id]
  end

  def update
    @round = Round.find_by_id params[:id]
    if @round.update_attributes(params[:round])
      flash[:notice] = "更新成功！"
      render :success
    else
      @notice = "更新失败！ #{@round.errors.messages.values.flatten.join("<br/>")}"
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
    user = User.find_all_by_email(session[:email])
    zipfile = params[:zip]
    base_url = "#{Rails.root}/public/qixueguan/tmp"
    @error_infos = []

    if !zipfile.nil?
      user_id = user[0].id
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
      if !File.directory? "#{zip_url}/#{zip_dir}"
        Dir.mkdir "#{zip_url}/#{zip_dir}"
      end
      begin
        Archive::Zip.extract "#{zip_url}/#{zip_dir}.zip","#{zip_url}/#{zip_dir}"
      rescue
      end
      File.delete "#{zip_url}/#{zip_dir}.zip"

      #excel文件与资源的根目录
      path = "#{base_url}/user_#{user_id}/#{zip_dir}"

      #获取excel文件数组和资源目录数组
      all_files = get_file_and_dir path

      #获取excel中题目的错误信息
      @error_infos = read_excel path,all_files[:excels]
      if !@error_infos.nil? && @error_infos.length != 0
        render :json => "#{@error_infos}"
        #respond_with(@error_infos) do |f|
        #  f.html
        #  f.js
        #end
      else #转移文件&插入数据&写入XML文件
        redirect_to course_chapter_rounds_path(@course.id,@chapter.id)
      end
    end
  end

  #解压压缩包、获取excel文件名和资源目录
  def unzip base_url, user_id, zip_dir
  end

  def get_file_and_dir path
    excel_files =  []
    resource_dirs = []

    #获取excel文件和资源目录
    Dir.entries(path).each do |sub|
      if sub != '.' && sub != '..'
        if File.directory?("#{path}/#{sub}")
          resource_dirs << sub.to_s
          #get_file_list("#{path}/#{sub}")
        else
          excel_files << sub.to_s
        end
      end
    end
    all_files = {:excels => excel_files.sort, :resource_dirs => resource_dirs}
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

  #识别题型
  def distinguish_question_types excel,que,line
    que_tpye = -1 #题型标记
    error_info = [] #错误信息

    #判断题目中的双括号（包括(())、[[]]、{{}}）是否成对
    sybs = []
    sybs << [ /\[\[|\]\]/,"[[","]]"] << [ /\(\(|\)\)/,"((","))"] << [ /\{\{|\}\}/,"{{","}}"]
    sybs.each do |syb|
      count = 0
      arr = que.scan(syb[0])
      #p arr
      l=arr.length.to_i-1

      (0..l).each do |i|
        #p arr[i]
        if arr[i+1] && arr[i] == arr[i+1]
          count = count + 1
        end
      end
      error_info << "Excel文件：#{excel} 第#{line}行：#{syb[1]}" + "……" + "#{syb[2]}符号不成对" if arr.length.to_i%2 != 0
      error_info << "Excel文件：#{excel} 第#{line}行：#{syb[1]}" + "……" + "#{syb[2]}符号中不能有#{syb[1]}或#{syb[2]}" if count > 0
    end

    count_a = 0	#[[]]计数
    result_a = []

    count_b = 0	#(())计数
    result_b = []

    count_c = 0	#{{}}计数
    result_c = []

    count_d = 0	#excel回车符计数
    result_d = []

    #匹配[[]]
    result_a = que.scan(/\[\[[^\[\[]*\]\]/)
    count_a = result_a.length if result_a.length != 0
    #p count_a

    #匹配(())
    result_b = que.scan(/\(\([^\(\(]*\)\)/)
    count_b = result_b.length if result_b.length != 0
    #p count_b

    #匹配{{}}
    result_c = que.scan(/\{\{[^\{\{]*\}\}/)
    count_c = result_c.length if result_c.length != 0
    #p count_c

    #匹配excel回车标记
    result_d = que.scan(%r{\n\s*})
    count_d = result_d.length if result_d.length != 0

    #p que.split(%r{\n\s*}) if double_bracket_d != 0

    #  p "---------------------------------------------------"
    #  count_e = 0		#||计数
    #  count_f = 0		#;;计数
    #  count_g = 0		#>>计数
    #  count_h = 0 	#@@计数

    if(count_a != 0 || count_b != 0 || count_c != 0)
        if(count_a == 1 && count_b == 0 && count_c == 0) #当只有一对[[]]时
            #可能题型：选择题、排序题、连线题、
            p "#{que}"
            tmp = result_a[0].to_s.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s
            count_e = tmp.scan(/\|\|/).length
            p count_e
            count_f = tmp.scan(/\;\;/).length
            p count_f
            if(count_e == 0 && count_f == 0) #当选项中没有||和;;分隔符
              que_tpye = -1 #未知题型
              error_info << "文件'#{excel}'第#{line}行：未知题型"
            elsif(count_e != 0 && count_f == 0) #当只有||分隔符 单选题、多选题、没有答案、连线题
                count = 0
                c = 0
                d = 0
                tmp.split(/\|\|/).to_a.each do |e|
                  p e
                  if e.to_s.match(/^@@.+/)
                    count = count + 1
                  end
                  if e.to_s.rstrip.match(/^@@$/)
                    c = c + 1
                  end
                  if e.to_s.gsub(/file>>>/,"file>;=;").gsub(/>>/,";=;").match(/;=;/)
                    d = d + 1
                  end
                end
                p "c#{c}"
                p "d#{d}"
                p "count#{count}"
                if count == 0
                  p "d#{d}"
                  p tmp.split(/\|\|/).length
                  if d != 0 && d == tmp.split(/\|\|/).length
                    g = 0
                    tmp.split(/\|\|/).to_a.each do |e|
                      e = e.gsub(/file>>>/,"file>;=;").to_s.gsub(/>>/,";=;").split(";=;")
                       if e.length != 2
                         g = g + 1
                       else
                          p  e[0].to_s.strip.empty?
                          p  e[1].to_s.strip.empty?
                          if e[0].to_s.strip.empty? || e[1].to_s.strip.empty?
                            g = g + 1
                          end
                       end
                    end

                    p "g:#{g}"
                    if g != 0
                      que_tpye = -1 #未知题型
                      error_info << "文件'#{excel}'第#{line}行：连线题对应关系不正确"
                    else
                      que_tpye = Question::TYPE_NAMES[:lineup] #连线题
                    end
                  elsif d != 0 && d < tmp.split(/\|\|/).length
                    que_tpye = -1 #未知题型
                    error_info << "文件'#{excel}'第#{line}行：连线题对应关系不正确"
                  elsif d == 0
                    que_tpye = -1 #未知题型
                    error_info << "文件'#{excel}'第#{line}行：选择题的没有答案或答案为空"
                  end
                elsif count == 1
                  if c != 0
                    que_tpye = -1 #未知题型
                    error_info << "文件'#{excel}'第#{line}行：选择题的没有答案或有答案为空"
                  else
                    que_tpye = Question::TYPE_NAMES[:single_choice] #单选题
                  end
                elsif count > 1
                  if c != 0
                    que_tpye = -1 #未知题型
                    error_info << "文件'#{excel}'第#{line}行：选择题的没有答案或有答案为空"
                  else
                    que_tpye = Question::TYPE_NAMES[:multiple_choice] #多选题
                  end
                end
            elsif(count_e == 0 && count_f != 0) #当只有;;分隔符 排序题
                count = 0
                tmp.split(/\;\;/).to_a.each do |e|
                   if e.to_s.strip.size == 0
                      count = count + 1
                   end
                end

                if count != 0 #当排序题选项为空时
                  que_tpye = -1 #未知题型
                  error_info << "文件'#{excel}'第#{line}行：排序题的选项不能为空"
                else
                  que_tpye = Question::TYPE_NAMES[:sortby] #排序题
                end
            end
        end

    #
    #              que_tpye = Question::TYPE_NAMES[:fillin] # 完型填空
    #            que_tpye = Question::TYPE_NAMES[:drag] # 拖拽题
    #          que_tpye = Question::TYPE_NAMES[:read_understanding] # 阅读理解
    #    que_tpye = Question::TYPE_NAMES[:input] #填空题
    #    que_tpye = Question::TYPE_NAMES[:voice_input] #口语题
    #  end
      #p "||total:#{count_e}  ;;total:#{count_f}  >>total:#{count_g}  @@total:#{count_h}"
      #p "[[]]total:#{count_a}  (())total:#{count_b}  {{}}total:#{count_c} ENTER total:#{count_d}"
    else
      que_tpye = -1 #未知题型
      error_info << "第#{line}行：未知题型"
    end
    result = {"que_tpye" => que_tpye, "error_info" => error_info }
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


    if type == Question::TYPE_NAMES[:single_choice]          #单选题截取方法
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

    elsif type == Question::TYPE_NAMES[:sortby]   #排序题
      branch_question_types = type
      options = que.scan(/\[\[[^\[\[]*\]\]/)[0].to_s.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s.gsub(/\;\;/,";||;").gsub(/;\|\|;$/,"")
      p options
      answer =options
      content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]")
      branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
                           :options => options, :answer => answer}
    elsif type == Question::TYPE_NAMES[:lineup]   #连线题
      branch_question_types = type
      options = que.scan(/\[\[[^\[\[]*\]\]/)[0].to_s.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s.gsub(/\|\|/,";||;")
      p options
      #options.split(";||;").each do |e|
      # p e
      # if e.match(/^\@\@.*/)
      #    if c != 0
      #      answer = answer +";||;"
      #    end
      #    answer = answer + e.gsub(/\@\@/,"")
      #    c = c + 1
      #  end
      #end
      #options = options.gsub(/@@/,"").gsub(/^;\|\|;/,"").gsub(/;\|\|;$/,"")
      #content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]")
      #branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
      #                     :options => options, :answer => answer}
    elsif type == Question::TYPE_NAMES[:fillin]   #完型填空题

    elsif type == Question::TYPE_NAMES[:sortby]   #排序题
      branch_question_types = type
      options = que.scan(/\[\[[^\[\[]*\]\]/)[0].to_s.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s.gsub(/\;\;/,";||;").gsub(/;\|\|;$/,"")
      p options
      answer =options
      content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]")
      branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
                           :options => options, :answer => answer}
    elsif type == Question::TYPE_NAMES[:voice_input]  #语音输入题

    elsif type == Question::TYPE_NAMES[:read_understanding] #阅读理解题

    elsif type == Question::TYPE_NAMES[:drag]     #拖拽题

    elsif type == Question::TYPE_NAMES[:input]    #填空题

    end
    question = {:content => content, :question_types => question_types, :branch_questions => branch_questions}
  end

  private

  def get_course_chapter
    @course = Course.find_by_id params[:course_id]
    @chapter = Chapter.find_by_id params[:chapter_id]
  end
end