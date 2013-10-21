#encoding: utf-8
module QuestionHelper
  #以时间重名名压缩包
  def rename_zip
    time_now = Time.now().to_s.slice(0,19).gsub(/\:/,'-')
    zip_dir = time_now.slice(0,10) + "_" + time_now.slice(11,8)
  end

  #上传文件
  def upload base_url, user_id, zip_dir, zipfile
    path = "#{base_url}/user_#{user_id}"
    if !File.directory? path
      Dir.mkdir path
    end

    #重命名zip压缩包为“年-月-日_时-分-秒”
    zipfile.original_filename = zip_dir + "." +  zipfile.original_filename.split(".").to_a[1]

    #上传文件
    begin
      if File.open(Rails.root.join("public", "qixueguan/tmp/user_#{user_id}", zipfile.original_filename), "wb") do |file|
        file.write(zipfile.read)
      end
        return true
      end
    rescue
      return false
    end
  end

  #解压zip题库压缩包
  def unzip zip_url, zip_dir
    path = "#{zip_url}/#{zip_dir}"
    if !File.directory? "#{zip_url}/#{zip_dir}"
      Dir.mkdir path
    end
    begin
      Archive::Zip.extract "#{path}.zip","#{path}"
      File.delete "#{path}.zip"
      return true
    rescue
      File.delete "#{path}.zip"
      Dir.delete "#{path}"
      return false
    end
  end

  #获取excel文件和资源目录
  def get_file_and_dir(path)
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

  #验证excel文件和资源目录
  def validate_file_and_dir files_and_dirs, number
    excels = files_and_dirs[:excels]
    dirs = files_and_dirs[:resource_dirs]
    error_info = [] #
    case number
      when "one"
        if excels.length == 1
          if dirs.length  > 1
            error_info << "只能有一个资源目录"
          elsif dirs.length == 1
              if excels[0].to_s.split(".")[0].to_s != dirs[0].to_s
                error_info << "资源目录与excel不对应"
              else
                error_info = []
              end
          else
            error_info = []
          end
        else
          error_info << "只能有一个excel"
        end
      when "more"
    end
    error_info
  end

  #读取一个excel中的题目
  def read_excel path, excel_files
    all_error_infos = [] #错误信息的集合
    all_round_questions = [] #所有个关卡所有题目的集合

    excel_files.each do |excel|
      result = read_questions path, excel
      result[:error_infos].each do |e|
        all_error_infos << e
      end
      #p result #一个excel的结果集
      all_round_questions << result
      #p all_round_questions

      #p "all_error_infos#{all_error_infos}"
    end
    if all_error_infos.length != 0
      all_error_infos
    else
      all_error_infos = ""
    end
    return_info = {:error_infos => all_error_infos, :all_round_questions => all_round_questions}
  end

  #读取一个excel题目
  def read_questions path, excel
    error_infos = [] #错误信息
    questions = []   #单个excel的题目集合
    begin
      oo = Roo::Excel.new("#{path}/#{excel}")
      oo.default_sheet = oo.sheets.first
      #p oo
    rescue
      error_infos << "#{excel}不是Excel文件"
      #      excel_files.delete(excel)
      #      read_excel path,excel_files
    end
    start_line = 0
    end_line = 0
    #questions = []

    #确定题目的开始行数
    end_line = oo.last_row.to_i
    if end_line  > 0
      1.upto(end_line) do |line|
        str = oo.cell(line,'A').to_s
        if str.size > 0
          if str == "Question" && start_line ==0
            start_line = line + 1
            break
          end
        end
      end
    else
      end_line = 0
    end

    round = oo.cell(2,'A').to_s  #关卡名称
    round_time = oo.cell(2,'B').to_s #关卡时间
    round_score = oo.cell(2,'C').to_s #关卡满分
    time_correct_percent = oo.cell(2,'D').to_s #时间正确率比
    blood = oo.cell(2,'E').to_s #血量

    #循环取出每一题
    start_line.upto(end_line).each do |line|
      que = oo.cell(line,'A').to_s
      card_name = oo.cell(line,'B').to_s
      card_types = oo.cell(line,'C').to_s
      card_description = oo.cell(line,'D').to_s

      type = -1
      error_info = ""

      #判断题型,题目信息错误验证
      result = distinguish_question_types excel,que,line
      p "result#{result}"
      error_info = result[:error_info]
      type = result[:que_tpye]
      error_infos << error_info if !error_info.empty?
      #p "error_infos#{error_infos.length}"
      if error_infos.length == 0 && type != -1
        questions << {:que => que, :type => type, :card_name => card_name, :card_types => card_types, :card_description => card_description}
        #split_question que,type 截取题目
      end
    end
    #p "error_infos#{error_infos}"
    return_info = {:round => round, :round_score => round_score, :round_time => round_time, :time_correct_percent => time_correct_percent, :blood => blood, :error_infos => error_infos, :questions => questions}
  end

  #判断题目中的双括号（包括(())、[[]]、{{}}）是否成对、及是否存在包含关系 未完成
  def brackets_validate que
    #按顺序取出题目中所有的双括号及多括号，放入数组
    double_brackets = que.scan(/\[\[|\]\]|\{\{|\}\}|\(\(|\)\)/)
    length  =  double_brackets.length
    status = []  #值为0和1, 1表示括号有问题, 0表示括号没有问题
    if que.scan(/\[\[{2,}|\]\]{2,}|\{\{{2,}|\}\}{2,}|\(\({2,}|\)\){2,}/).length != 0
      status = 1
    elsif length%2 != 0
      status = 1
    elsif length%2 == 0
      length = double_brackets.length
      result = []

      (0..(length-1)).each do |i|
        if i%2==0 && i < length
          e = double_brackets[i].to_s
          f = double_brackets[i+1].to_s
          if e.scan(/\(\(/).length == 1
            if f.scan(/\)\)/).length == 1
                result << true
            else
                result << false
             end
          elsif e.scan(/\[\[/).length == 1
              if f.scan(/\]\]/).length == 1
                result << true
              else
                result << false
              end
          elsif e.scan(/\{\{/).length == 1
              if f.scan(/\}\}/).length == 1
                result << true
              else
                result << false
              end
          else
              result << false
          end
        end
      end  #(0..(length-1)).each do |i|
      count = 0
      result.each do |e|
        if e ==false
          count = count + 1
        end
      end
    end #if que.scan(/\[\[{2,}|\]\]{2,}|\{\{{2,}|\}\}{2,}|\(\({2,}|\)\){2,}/).length != 0

    if count == 0
      return 0
    else
      return 1
    end
  end

  #识别题型
  def distinguish_question_types excel,que,line
    que_tpye = -1 #题型标记
    error_info = "" #错误信息
    p "---------------------------------------------------"
    p "que:#{que}"
    if brackets_validate(que) == 1
        error_info = "文件'#{excel}'第#{line}行：双括号配对不完整、双括号存在嵌套或存在两个以上的连续括号"
        p error_info
    end

      count_a = 0	#[[]]计数
      count_b = 0	#(())计数
      count_c = 0	#{{}}计数
      count_d = 0	#excel回车符计数
      #p "que#{que}"
      #匹配[[]]
      result_a = que.scan(/\[\[[^\[\[]*\]\]/)
      count_a = result_a.length if result_a.length != 0
      #匹配(())
      result_b = que.scan(/\(\([^\(\(]*\)\)/)
      count_b = result_b.length if result_b.length != 0
      #匹配{{}}
      result_c = que.scan(/\{\{[^\{\{]*\}\}/)
      count_c = result_c.length if result_c.length != 0
      #匹配excel回车标记
      result_d = que.scan(%r{\n\s*})
      count_d = result_d.length if result_d.length != 0

      #  count_e = 0 #||计数     #  count_f = 0		#;;计数
      #  count_g = 0 #>>计数     #  count_h = 0 	  #@@计数
      if(count_a != 0 || count_b != 0 || count_c != 0)   #[[]]、(())、{{}}的数量不能都为0
        if count_a == 1 && count_b == 0 && count_c == 0 #当只有一对[[]]时
             #单选题、多选题、排序题、连线题的判断及验证
             tmp_val =  distinguish_question_one excel, line, result_a
             que_tpye = tmp_val[:que_tpye]
             error_info = tmp_val[:error_info]
        elsif count_a > 1 && count_b == 0 && count_c == 0 && result_d.length == 0
            #拖拽题和完形填空题的判断及验证
            tmp_val = distinguish_question_two excel, line, result_a
            que_tpye = tmp_val[:que_tpye]
            error_info = tmp_val[:error_info]
        elsif count_b >= 1 && count_a == 0 && count_c == 0  #填空题的
            que_tpye = Question::TYPE_NAMES[:input] #填空题
            p "文件'#{excel}'第#{line}行：填空题"
        elsif count_c != 0 && count_a == 0 && count_b == 0   #语音输入题
            que_tpye = Question::TYPE_NAMES[:voice_input] # 语音输入题
            p "文件'#{excel}'第#{line}行：语音输入题"
        elsif count_d != 0   # 综合题
            tmp_val = distinguish_question_three excel, line, que
            que_tpye = tmp_val[:que_tpye]
            error_info = tmp_val[:error_info]
        end
      else
        que_tpye = -2 #题面，没有选项的括号标记
      end
    #p "||total:#{count_e}  ;;total:#{count_f}  >>total:#{count_g}  @@total:#{count_h}"
    p "que_tpye:#{que_tpye}"
    p "error_info:#{error_info}"
    return_infos = {:que_tpye => que_tpye, :error_info => error_info }
  end

  #单选题、多选题、排序题、连线题的判断及验证
  def distinguish_question_one excel, line, result_a
    que_tpye = -1 #题型标记
    error_info = "" #错误信息
    #return_info = {}
    tmp = result_a[0].to_s.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s
    #p tmp
    count_e = tmp.scan(/\|\|/).length
    count_f = tmp.scan(/\;\;/).length
    #p count_e
    #p count_f
    if(count_e == 0 && count_f == 0) #当选项中没有||和;;分隔符
      que_tpye = -1 #未知题型
      error_info = "文件'#{excel}'第#{line}行：未知题型"
    elsif(count_e != 0 && count_f == 0) #当只有||分隔符 单选题、多选题、没有答案、连线题
      count = 0
      c = 0
      d = 0
      tmp.split(/\|\|/).to_a.each do |e|
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
      #p "#{count}count"
      if count == 0
        if d != 0 && d == tmp.split(/\|\|/).length
          g = 0
          tmp.split(/\|\|/).to_a.each do |e|
            e = e.gsub(/file>>>/,"file>;=;").to_s.gsub(/>>/,";=;").split(";=;")
            if e.length != 2
              g = g + 1
            else
              if e[0].gsub(/^||/,"").to_s.strip.empty? || e[1].gsub(/^||/,"").to_s.strip.empty?
                g = g + 1
              end
            end
          end

          if g != 0
            que_tpye = -1 #未知题型
            error_info = "文件'#{excel}'第#{line}行：连线题对应关系不正确"
          else
            que_tpye = Question::TYPE_NAMES[:lineup] #连线题
            p "文件'#{excel}'第#{line}行：连线题"
          end
        elsif d != 0 && d < tmp.split(/\|\|/).length
          que_tpye = -1 #未知题型
          error_info = "文件'#{excel}'第#{line}行：连线题对应关系不正确"
        elsif d == 0
          que_tpye = -1 #未知题型
          error_info = "文件'#{excel}'第#{line}行：选择题的没有答案或答案为空"
        end
      elsif count == 1
        #p "c#{c}"
        if c != 0
          que_tpye = -1 #未知题型
          error_info = "文件'#{excel}'第#{line}行：选择题的没有答案或有答案为空"
        else
          p "文件'#{excel}'第#{line}行：单选题"
          que_tpye = Question::TYPE_NAMES[:single_choice] #单选题
        end
      elsif count > 1
        if c != 0
          que_tpye = -1 #未知题型
          error_info = "文件'#{excel}'第#{line}行：选择题的没有答案或有答案为空"
        else
          p "文件'#{excel}'第#{line}行：多选题"
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
        error_info = "文件'#{excel}'第#{line}行：排序题的选项不能为空"
      else
        que_tpye = Question::TYPE_NAMES[:sortby] #排序题
        p "文件'#{excel}'第#{line}行：排序题"
      end
    end
    #p "one_error_info#{error_info}"
    #p "one_que_tpye#{que_tpye}"
    return_info = {:que_tpye => que_tpye, :error_info => error_info }
  end

  #拖拽题和完形填空题的判断及验证
  def distinguish_question_two excel, line, result_a
    que_tpye = -1 #题型标记
    error_info = "" #错误信息
    #return_info = {}
    tmp = []
    result_a.each do |r|
      tmp << r.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s
    end

    result = []
    #循环匹配一个[[]]中的内容，看每个[[]]里有几个||符号
    tmp.each do |e|
      result <<  e.to_s.scan("||").length
    end

    count_zero = 0
    count_one = 0
    result.each do |e|
      if e >= 1
        count_one = count_one + 1  #对有||的选项计数
      else
        count_zero = count_zero + 1 #对没有有||的选项计数
      end
    end

    if count_one == 0 && count_zero != 0 && count_zero == result.length  #拖拽题
      que_tpye = Question::TYPE_NAMES[:drag] # 拖拽题
      p "文件'#{excel}'第#{line}行：拖拽题"
    elsif count_zero == 0 && count_one != 0 && count_one == result.length #完型填空题
      #完型填空题的判断和验证
      t = distinguish_question_four excel, line, tmp
      que_tpye = t[:que_tpye]
    else
      error_info = "文件'#{excel}'第#{line}行：完形填空题的每个选项[[……]]中至少有一个必须有'||'或拖拽题的每个选项[[……]]中都不能有'||'"
    end
    #p error_info
    #p que_tpye
    return_info = {:que_tpye => que_tpye, :error_info => error_info}
  end

  #综合题的判断和验证
  def distinguish_question_three excel, line, que
    que_tpye = -1
    error_info = []
    return_info = {}
    tmp =  que.split(%r{\n\s*})
    #p tmp
    types = [] #完型填空中的所有小题类型的集合
    errorinfo = ""
    tmp.each do |e|
      t = distinguish_question_types(excel, e, line)
      types <<  t[:que_tpye]
      errorinfo = t[:error_info]
      p "errorinfo#{errorinfo}"
    end
    count = 0
    types.each  do |e|
      if(e == -1 || e > 8)
        count = count + 1
      end
    end

    if count == 0
      que_tpye = Question::TYPE_NAMES[:zonghe]
      p "文件'#{excel}'第#{line}行：综合题"
    else
      que_tpye = -1
      error_info = errorinfo
    end
    #p error_info
    #p que_tpye
    return_info = {:que_tpye => que_tpye, :error_info => error_info}
  end

  #完型填空题的判断及验证
  def distinguish_question_four excel, line, tmp
    que_tpye = -1 #题型标记
    error_info = "" #错误信息

    result = [] #统计每个选项里的答案数,即@@个数
    tmp.each do |e|
      g = 0 #统计一个选项中的答案个数，即@@个数
      e.gsub(/^\|\|/,"").split("||").each do |x|
        if x.to_s.lstrip.match(/^@@/)
          g = g + 1
        end
        #p "x = " + x if x.to_s.lstrip.match(/^@@/)
      end
      result << g
    end
    count_zero = 0 #计数完形填空中没有答案的选项个数
    count_one_more = 0  #计数完形填空中超过一个答案的选项个数
    result.each do |e|
      if e == 0
        count_zero = count_zero + 1
      elsif e > 1
        count_one_more = count_one_more + 1
      else
      end
    end
    if count_zero == 0 && count_one_more == 0
      que_tpye = Question::TYPE_NAMES[:fillin] # 完型填空
      p "文件'#{excel}'第#{line}行：完形填空"
    elsif count_zero != 0 || count_one_more != 0
      error_info = "文件'#{excel}'第#{line}行：完形填空完型填空题中的某个选项没答案或有多个答案"
    end
    #p error_info
    #p que_tpye
    return_info = {:que_tpye => que_tpye, :error_info => error_info}
  end

  #截取题目中的大题，小题与选项
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
    elsif type == Question::TYPE_NAMES[:zonghe] #综合题
      p "综合题截取"
      tmp = que.to_s.split(%r{\n\s*})
      tmp.each do |e|
        result = p distinguish_question_types excel="", e, line=""
        if result[:que_tpye] == -2
          content = content + e
        else
          branch_que =  split_question e, result[:que_tpye]
          p branch_que
          branch_questions << {:branch_content => branch_que[:content], :branch_question_types => branch_que[:question_types],
                               :options => branch_que[:branch_questions][0][:options], :answer => branch_que[:branch_questions][0][:answer]}
        end
      end
      #branch_question_types = type
      #options = que.scan(/\{\{[^\{\{]*\}\}/)[0].to_s.scan(/(?<=\{\{).*(?=\}\})/).to_a[0]
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

  #导入数据
  def import_data all_round_questions, course_id, chapter_id
    all_round_questions.each do |e|
      json_file = ""
      round_name = e[:round].to_s.strip
      round_score = e[:round_score].to_i
      round_time = e[:round_score].to_i
      time_correct_percent = e[:round_score].to_i
      blood = e[:round_score].to_i
      round_score = e[:round_score].to_i
      questions = e[:questions]
      round = Round.find_by_course_id_and_chapter_id_and_name(course_id, chapter_id, round_name)
      course = Course.find(course_id)
      if round
        if !round_name.strip.empty? && round_score != 0 && round_time != 0 && time_correct_percent != 0 && blood != 0

          course.update_attributes(:max_score => round_score, :time_ratio => time_correct_percent, :round_time => round_time, :blood => blood )
          round.update_attributes(:max_score => round_score, :time_ratio => time_correct_percent, :round_time => round_time, :blood => blood )

        else
          round = Round.create(:name => round_name, :max_score => course.max_score, :time_ratio => course.time_ratio, :round_time => course.round_time, :blood => course.blood , :chapter_id => chapter_id, :course_id => course.id)
        end
      else
        if !round_name.strip.empty? && round_score != 0 && round_time != 0 && time_correct_percent != 0 && blood != 0
          round = Round.create(:name => round_name, :max_score => round_score, :time_ratio => time_correct_percent, :round_time => round_time, :blood => blood )
        else


          Round.create(:name => round_name, :max_score => course.max_score, :time_ratio => course.time_ratio, :round_time => course.round_time, :blood => course.blood )
        end
      end
      p course
      p "questions#{questions}"
      one_json_question = []
      questions.each do |x|
        p x
        result = split_question x[:que].to_s, x[:type]
        p "result#{result}"
        knowledge_card = KnowledgeCard.create(:name => x[:card_name].to_s, :types => x[:card_types], :description => x[:card_description].to_s, :course_id => course.id)

        question = Question.create(:knowledge_card_id => knowledge_card.id, :content => result[:content], :types => result[:question_types], :round_id => round.id)
        p question
        branch_questions =[]
        result[:branch_questions].each do |i|
          branch_questions << BranchQuestion.create(:question_id => question.id, :branch_content => i[:branch_content], :types => i[:branch_question_types], :options => i[:options], :answer => i[:answer] )
        end

        branch_ques = []
        branch_questions.each do |y|
          branch_ques <<  {:branch_question_id => y.id, :branch_content=> y.branch_content, :branch_question_types => y.types,:options => y.options,:answer => y.answer}.to_json
        end
        p "#{branch_ques}"
        one_json_question << {}
      end
      p "====================================="

    end
  end

end
