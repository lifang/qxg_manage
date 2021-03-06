#encoding: utf-8
require 'rake/file_utils'
require 'archive/zip'
require 'iconv'

module QuestionHelper
  #以时间重名名压缩包文件
  def rename_file
    time_now = Time.now().to_s.slice(0,19).gsub(/\:/,'-')
    filename = time_now.slice(0,10) + "_" + time_now.slice(11,8)
  end

  #上传文件
  def upload path, zip_dir, zipfile
    #创建目录
    url = "/"
    count = 0
    path.split("/").each_with_index  do |e,i|
      if i > 0 && e.size > 0
        url = url + "/" if count > 0
        url = url + "#{e}"
        if !Dir.exist? url
          Dir.mkdir url
        end
        count = count +1
      end
    end

    #重命名zip压缩包为“年-月-日_时-分-秒”
    zipfile.original_filename = zip_dir + "." +  zipfile.original_filename.split(".").to_a[1]
    file_url = "#{path}/#{zipfile.original_filename}"
    #上传文件
    begin
      if File.open(file_url, "wb") do |file|
        file.write(zipfile.read)
      end
        return true
      end
    rescue
      File.delete file_url
      return false
    end
  end

  #解压zip题库压缩包
  def unzip zip_url
    Dir.mkdir zip_url if !File.directory? zip_url
    begin
      Archive::Zip.extract "#{zip_url}.zip","#{zip_url}"
      File.delete "#{zip_url}.zip"
      `convmv -f gbk -t utf-8 -r --notest  #{zip_url}`
      return true
    rescue
      File.delete "#{zip_url}.zip"
      FileUtils.remove_dir zip_url
      return false
    end
  end

  #获取excel文件和资源目录
  def get_excels_and_dirs(path)
    excels =  []
    dirs = []
    #获取excel文件和资源目录
    Dir.entries(path).each do |sub|
      if sub != '.' && sub != '..'
        if File.directory?("#{path}/#{sub}")
          dirs << sub.to_s
        else
        #  excels << sub.to_s if sub.to_s.split(".")[1]== "xls"
          excels << sub.to_s if File.extname(sub.to_s)== ".xls"
        end
      end
    end
    if excels.length == 0
      excels = []
    else
      excels.sort!
    end
    p excels
    all_files = {:excels => excels, :dirs => dirs}
  end

  #验证excel文件名称
  def check_excel_name excels
    error_infos = []
    status = 1
    excels.each  do |excel|

      if excel.scan(/\p{Han}/).to_a.length != 0
        error_infos << "excel文件：'#{excel}'文件名中不能包含中文，请重新命名后打包上传"
        status = 1
      end
      if File.basename(excel,".xls").match(/^[a-zA-Z]+$/) || File.basename(excel,".xls").match(/^[a-zA-Z]+[0-9]*$/)
        status = 0
      else
        error_infos << "excel文件：'#{excel}'文件名没有按照约定格式'字母+数字'命名，请重新命名后打包上传"
        status = 1
      end
    end
    all_info = {:status => status, :error_infos => error_infos }
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
      all_round_questions << result
    end
    if all_error_infos.length != 0
      all_error_infos
    else
      all_error_infos = ""
    end
    return_info = {:error_infos => all_error_infos, :all_round_questions => all_round_questions}
  end

  #读取excel中一道题
  def read_questions path, excel
    error_infos = [] #错误信息
    questions = []   #单个excel的题目集合
    begin
      oo = Roo::Excel.new("#{path}/#{excel}")
      oo.default_sheet = oo.sheets.first
    rescue
      error_infos << "#{excel}不是Excel文件"
    end
    start_line = 0
    end_line = 0
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
    round.strip!
    round_time.strip!
    round_score.strip!
    time_correct_percent.strip!
    blood.strip!
    if round.size == 0
      error_infos << "文件'#{excel}'关卡的名称不能为空"
    end
    if round_time.size != 0 && round_time.to_i <= 0
      error_infos << "文件'#{excel}'关卡时间必须大于0"
    end
    if round_score.size != 0 && round_score.to_i <= 0
      error_infos << "文件'#{excel}'关卡得分必须大于0"
    end
    if time_correct_percent.size != 0 && (time_correct_percent.to_i <= 0 || time_correct_percent.to_i >= 100)
      error_infos << "文件'#{excel}'关卡的'时间和正确率比例'字段取值不正确(正确取值范围：1-99)"
    end
    if blood.size != 0 && blood.to_i <= 0
      error_infos << "文件'#{excel}'关卡血量必须大于0"
    end
    round_time = round_time.to_i
    round_score = round_score.to_i
    time_correct_percent = time_correct_percent.to_i
    blood = blood.to_i

    #循环取出每一题
    start_line.upto(end_line).each do |line|
      que = oo.cell(line,'A').to_s
      card_name = oo.cell(line,'B').to_s
      card_types = oo.cell(line,'C').to_s
      card_description = oo.cell(line,'D').to_s
      card_name.strip!
      card_types.strip!
      card_description.strip!

      if que.size == 0
        error_infos << "文件'#{excel}'第#{line}行：题目内容为空"
      else
        if brackets_validate(que) == 1
          error_infos << "文件'#{excel}'第#{line}行：双括号配对不完整、双括号存在嵌套或存在两个以上的连续括号"
        else
          type = -1
          #判断题型,题目信息错误验证
          result = distinguish_question_types excel,que,line
          error_info = result[:error_info]
          type = result[:que_tpye]
          error_info.each do |e|
            error_infos << e.to_s.strip if e.to_s.strip.size != 0
          end
        end
      end

      if card_name.size == 0 && card_types.size == 0 && card_description.size == 0
      elsif card_name.size != 0 && card_types.size != 0 && card_description.size != 0
      else
         error_infos << "文件'#{excel}'第#{line}行：知识卡片名称、知识卡片标签、知识卡片描述三个字段要么都为空，要么都不为空"
      end

      if type == -2
        error_infos << "文件'#{excel}'第#{line}行：没有任何题型标记，未知题型"
      end

      if error_infos.length == 0 && type != -1
        questions << {:que => que, :type => type, :card_name => card_name, :card_types => card_types, :card_description => card_description}
      end
    end
    return_info = {:round => round, :round_score => round_score, :round_time => round_time, :time_correct_percent => time_correct_percent, :blood => blood, :excel => excel, :error_infos => error_infos, :questions => questions}
  end

  #判断题目中的双括号（包括(())、[[]]、{{}}）是否成对、及是否存在包含关系 未完成
  def brackets_validate que
    #按顺序取出题目中所有的双括号及多括号，放入数组
    double_brackets = que.scan(/\[\[|\]\]|\{\{|\}\}|\(\(|\)\)/)
    length  =  double_brackets.length
    if length > 0
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
          count = count + 1 if e ==false
        end
      end #if que.scan(/\[\[{2,}|\]\]{2,}|\{\{{2,}|\}\}{2,}|\(\({2,}|\)\){2,}/).length != 0
    else
       count = 0
    end
    if count == 0
      return 0
    else
      return 1
    end
  end

  #识别题型
  def distinguish_question_types excel,que,line
    que_tpye = -1 #题型标记
    error_info = [] #错误信息

      count_a = 0	#[[]]计数
      count_b = 0	#(())计数
      count_c = 0	#{{}}计数
      count_d = 0	#excel回车符计数
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

      #  count_e = 0 #||计数     #  count_f = 0   #;;计数
      #  count_g = 0 #>>计数     #  count_h = 0   #@@计数
      if(count_a != 0 || count_b != 0 || count_c != 0)   #[[]]、(())、{{}}的数量不能都为0
        if count_a == 1 && count_b == 0 && count_c == 0 #当只有一对[[]]时
             #单选题、多选题、排序题、连线题的判断及验证
             tmp_val =  distinguish_question_one excel, line, result_a
             que_tpye = tmp_val[:que_tpye]
             tmp_val[:error_info].each do |e|
              error_info << e.to_s.strip if e.to_s.strip.size != 0
             end
        elsif count_a > 1 && count_b == 0 && count_c == 0 && result_d.length == 0
            #拖拽题和完形填空题的判断及验证
            tmp_val = distinguish_question_two excel, line, result_a
            que_tpye = tmp_val[:que_tpye]
            tmp_val[:error_info].each do |e|
              error_info << e.to_s.strip if e.to_s.strip.size != 0
            end
        elsif count_b >= 1 && count_a == 0 && count_c == 0  #填空题
            count_e = 0
            result_b.each do |e|
              count_e+= 1 if e.scan(/\(\([\s]*\)\)/).length != 0
            end
            if count_e != 0
              que_tpye = -1
              if excel.size == 0 || line.size == 0
                error_info << "填空题内容不能为空"
              else
                error_info << "文件'#{excel}'第#{line}行：填空题内容不能为空"
              end
            else
              que_tpye = Constant::QUESTION_TYPE_NAMES[:input] #填空题
            end
        elsif count_c != 0 && count_a == 0 && count_b == 0   #语音输入题
            count_f = 0
            result_c.each do |e|
              count_f += 1 if e.scan(/\{\{[\s]*\}\}/).length != 0
            end
            if count_f != 0
              que_tpye = -1
              if excel.size == 0 || line.size == 0
                error_info << "语音输入题内容不能为空"
              else
                error_info << "文件'#{excel}'第#{line}行：语音输入题内容不能为空"
              end
            else
              que_tpye = Constant::QUESTION_TYPE_NAMES[:voice_input] # 语音输入题
            end
        elsif count_d != 0   # 综合题
            tmp_val = distinguish_question_three excel, line, que
            que_tpye = tmp_val[:que_tpye]
            tmp_val[:error_info].each do |e|
              error_info << e.to_s.strip if e.to_s.strip.size != 0
            end
        else
          que_type = -1
          if excel.size == 0 || line.size == 0
            error_info << "未知题型"
          else
            error_info << "文件'#{excel}'第#{line}行：未知题型"
          end
        end
      else
        que_tpye = -2 #题面，没有选项的括号标记
      end
    return_infos = {:que_tpye => que_tpye, :error_info => error_info }
  end

  #单选题、多选题、排序题、连线题的判断及验证
  def distinguish_question_one excel, line, result_a
    que_tpye = -1 #题型标记
    error_info = [] #错误信息
    tmp = result_a[0].to_s.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s
    count_e = tmp.scan(/\|\|/).length
    count_f = tmp.scan(/\;\;/).length

    if(count_e == 0 && count_f == 0) #当选项中没有||和;;分隔符
      if tmp.match(/^\>\>/) || tmp.match(/\>\>$/)
        que_type = -1 #未知题型
        if excel.size == 0 || line.size == 0
          error_info << "连线题对应关系不能为空"
        else
          error_info << "文件'#{excel}'第#{line}行：连线题对应关系不完整"
        end
      elsif tmp.scan(">>").length != 0 || tmp.scan("file>>>").length != 0
        que_type = -1 #未知题型
        if excel.size == 0 || line.size == 0
          error_info << "连线题不能只有一对对应关系"
        else
          error_info << "文件'#{excel}'第#{line}行：连线题不能只有一对对应关系"
        end
      else
        que_tpye = -1 #未知题型
        if excel.size == 0 || line.size == 0
          error_info << "未知题型"
        else
          error_info << "文件'#{excel}'第#{line}行：未知题型"
        end
      end
    elsif(count_e != 0 && count_f == 0) #当只有||分隔符 单选题、多选题、没有答案、连线题
      count = 0
      c = 0
      d = 0
      tmp.split(/\|\|/).to_a.each do |e|
        count = count + 1 if e.to_s.match(/^@@.+/)
        c = c + 1 if e.to_s.rstrip.match(/^@@$/)
        d = d + 1 if e.to_s.gsub(/file>>>/, "file>;=;").gsub(/>>/, ";=;").match(/;=;/)
      end
      if count == 0
        if d != 0 && d == tmp.split(/\|\|/).length
          g = 0
          tmp.split(/\|\|/).to_a.each do |e|
            e = e.gsub(/file>>>/,"file>;=;").to_s.gsub(/>>/,";=;").split(";=;")
            if e.length != 2
              g = g + 1
            else
              g = g + 1 if e[0].gsub(/^||/, "").to_s.strip.empty? || e[1].gsub(/^||/, "").to_s.strip.empty?
            end
          end

          if g != 0
            que_tpye = -1 #未知题型
            if excel.size == 0 || line.size == 0
              error_info << "连线题对应关系不正确"
            else
              error_info << "文件'#{excel}'第#{line}行：连线题对应关系不正确"
            end
          else
            que_tpye = Constant::QUESTION_TYPE_NAMES[:lineup] #连线题
          end
        elsif d != 0 && d < tmp.split(/\|\|/).length
          que_tpye = -1 #未知题型
          if excel.size == 0 || line.size == 0
            error_info << "连线题对应关系不正确"
          else
            error_info << "文件'#{excel}'第#{line}行：连线题对应关系不正确"
          end
        elsif d == 0
          que_tpye = -1 #未知题型
          if excel.size == 0 || line.size == 0
            error_info << "选择题没有答案或答案为空"
          else
            error_info << "文件'#{excel}'第#{line}行：选择题没有答案或答案为空"
          end
        end
      elsif count == 1
        if c != 0
          que_tpye = -1 #未知题型
          if excel.size == 0 || line.size == 0
            error_info << "选择题没有答案或答案为空"
          else
            error_info << "文件'#{excel}'第#{line}行：选择题没有答案或答案为空"
          end
        else
          que_tpye = Constant::QUESTION_TYPE_NAMES[:single_choice] #单选题
        end
      elsif count > 1
        if c != 0
          que_tpye = -1 #未知题型
          if excel.size == 0 || line.size == 0
            error_info << "选择题没有答案或答案为空"
          else
            error_info << "文件'#{excel}'第#{line}行：选择题没有答案或答案为空"
          end
        else
          que_tpye = Constant::QUESTION_TYPE_NAMES[:multiple_choice] #多选题
        end
      end
    elsif(count_e == 0 && count_f != 0) #当只有;;分隔符 排序题
      count = 0
      options = tmp.split(/\;\;/)
      if options.length == 0
        que_tpye = -1 #未知题型
        if excel.size == 0 || line.size == 0
          error_info << "排序题的选项不能为空"
        else
          error_info << "文件'#{excel}'第#{line}行：排序题的选项不能为空"
        end
      elsif options.length == 1
        que_tpye = -1 #未知题型
        if excel.size == 0 || line.size == 0
          error_info << "排序题的选项不能为空"
        else
          error_info << "文件'#{excel}'第#{line}行：排序题的选项个数必须在一个以上"
        end
      else
        options.each do |e|
          count = count + 1 if e.to_s.strip.size == 0
        end
        if count != 0 #当排序题选项为空时
          que_tpye = -1 #未知题型
          if excel.size == 0 || line.size == 0
            error_info << "排序题的选项不能为空"
          else
            error_info << "文件'#{excel}'第#{line}行：排序题的选项不能为空"
          end
        else
          que_tpye = Constant::QUESTION_TYPE_NAMES[:sortby] #排序题
        end
      end
    end
    return_info = {:que_tpye => que_tpye, :error_info => error_info }
  end

  #拖拽题和完形填空题的判断及验证
  def distinguish_question_two excel, line, result_a
    que_tpye = -1 #题型标记
    error_info = [] #错误信息
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
      count = 0 #对;;符号和@@符号计数
      tmp.each do |e|
        count += 1 if e.to_s.scan("@@").length != 0
        count += 1 if e.to_s.scan(";;").length != 0
      end
      if count == 0
        que_tpye = Constant::QUESTION_TYPE_NAMES[:drag] # 拖拽题
      else
        if excel.size == 0 || line.size == 0
          error_info << "拖拽题中不能包含';;'符号或'@@'符号"
        else
          error_info << "文件'#{excel}'第#{line}行：拖拽题中不能包含';;'符号或'@@'符号"
        end
      end
    elsif count_zero == 0 && count_one != 0 && count_one == result.length #完型填空题
      #完型填空题的判断和验证
      t = distinguish_question_four excel, line, tmp
      que_tpye = t[:que_tpye]
      t[:error_info].each do |e|
        error_info << e.to_s.strip if e.to_s.strip.size != 0
      end
    else
      if excel.size == 0 || line.size == 0
        error_info << "完形填空题的每个选项[[……]]中至少有一个'||'/拖拽题的每个选项[[……]]中都不能有'||'"
      else
        error_info << "文件'#{excel}'第#{line}行：完形填空题的每个选项[[……]]中至少有一个必须有'||'或拖拽题的每个选项[[……]]中都不能有'||'"
      end
    end
    return_info = {:que_tpye => que_tpye, :error_info => error_info}
  end

  #综合题的判断和验证
  def distinguish_question_three excel, line, que
    que_tpye = -1
    error_info = []
    return_info = {}
    tmp =  que.split(%r{\n\s*})
    types = [] #完型填空中的所有小题类型的集合
    tmp.each do |e|
      t = distinguish_question_types("", e, "")
      types <<  t[:que_tpye]
      if t[:error_info].length != 0
        if excel.size == 0 || line.size == 0
          t[:error_info].each do |e|
            error_info << "综合题中#{e}"
          end
        else
          t[:error_info].each do |e|
            error_info << "文件'#{excel}'第#{line}行综合题中:#{e}"
          end
        end
      end
    end
    count = 0 #计数不属于综合题的题型
    count_a = 0 #大题的内容
    types.each  do |e|
      count += 1 if (e == -1 || e > 8)
      count += 1 if e >= 2 && e <= 4
      count += 1 if e >= 6 && e <= 7
      count_a += 1 if e == -2
    end

    if count_a != 0 && count == 0
      que_tpye = Constant::QUESTION_TYPE_NAMES[:zonghe]
    elsif count_a == 0 && count == 0
      que_tpye = -1
      if excel.size == 0 || line.size == 0
        error_info << "综合题大题的内容不能为空！"
      else
        error_info << "文件'#{excel}'第#{line}行综合题大题的内容不能为空！"
      end
    elsif count_a != 0 && count != 0
      if excel.size == 0 || line.size == 0
        error_info << "综合题的小题只能是单选题、多选题、填空题、语音题！"
      else
        error_info << "文件'#{excel}'第#{line}行综合题的小题只能是单选题、多选题、填空题、语音题！"
      end
    end
    return_info = {:que_tpye => que_tpye, :error_info => error_info}
  end

  #完型填空题的判断及验证
  def distinguish_question_four excel, line, tmp
    que_tpye = -1 #题型标记
    error_info = [] #错误信息

    result = [] #统计每个选项里的答案数,即@@个数
    tmp.each do |e|
      g = 0 #统计一个选项中的答案个数，即@@个数
      e.gsub(/^\|\|/,"").split("||").each do |x|
        g = g + 1 if x.to_s.lstrip.match(/^@@/)
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
      que_tpye = Constant::QUESTION_TYPE_NAMES[:fillin] # 完型填空
    elsif count_zero != 0 || count_one_more != 0
      if excel.size == 0 || line.size == 0
        error_info << "完型填空题中的某个选项没答案或有多个答案"
      else
        error_info << "文件'#{excel}'第#{line}行：完型填空题中的某个选项没答案或有多个答案"
      end
    end
    return_info = {:que_tpye => que_tpye, :error_info => error_info}
  end

  #截取题目中的大题，小题与选项
  def split_question que, type
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

    if type == Constant::QUESTION_TYPE_NAMES[:single_choice]          #单选题
      branch_question_types = type
      options = que.scan(/\[\[[^\[\[]*\]\]/)[0].to_s.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s.gsub(/\|\|/,";||;")
      options.split(";||;").each do |e|
        answer = e.to_s.scan(/[^\@\@].*/)[0].to_s if e.to_s.match(/^@@.*/)
      end
      options = options.gsub(/@@/,"").gsub(/^;\|\|;/,"").gsub(/;\|\|;\s*$/,"")
      #content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]")
      content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]").gsub(/\[\[text\]\]$/,"")
      branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
                           :options => options, :answer => answer}
    elsif type == Constant::QUESTION_TYPE_NAMES[:multiple_choice]   #多选题
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
      options = options.gsub(/@@/,"").gsub(/^;\|\|;/,"").gsub(/;\|\|;\s*$/,"")
      #content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]")
      content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]").gsub(/\[\[text\]\]$/,"")
      branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
                           :options => options, :answer => answer}
    elsif type == Constant::QUESTION_TYPE_NAMES[:fillin]   #完型填空题
      branch_question_types = type
      all_answers = []
      all_options = []
      result = que.scan(/\[\[[^\[\[]*\]\]/)
      result.each do |e|
        e = e.scan(/(?<=\[\[).*(?=\]\])/)[0].to_s.gsub(/\|\|/,";||;")
        e.split(";||;").to_a.each do |x|
          all_answers << x.gsub(/^@@/, "").to_s if x.lstrip.match(/^@@.+/)
        end
        all_options <<  e.gsub(/@@/,"").gsub(/^;\|\|;/,"").gsub(/;\|\|;\s*$/,"")
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
    elsif type == Constant::QUESTION_TYPE_NAMES[:sortby]   #排序题
      branch_question_types = type
      options = que.scan(/\[\[[^\[\[]*\]\]/)[0].to_s.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s.gsub(/\;\;/,";||;").gsub(/;\|\|;$/,"")
      answer =options
      #content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]")
      content = que.gsub(/\[\[[^\[\[]*\]\]/,"")
      branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
                           :options => options, :answer => answer}
    elsif type == Constant::QUESTION_TYPE_NAMES[:lineup]   #连线题
      branch_question_types = type
      options = que.scan(/\[\[[^\[\[]*\]\]/)[0].to_s.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s.gsub(/\|\|/,";||;").gsub(/file>>>/,"file>;=;").gsub(/>>/,";=;")
      answer =options
      #content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]")
      content = que.gsub(/\[\[[^\[\[]*\]\]/,"")
      branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
                           :options => options, :answer => answer}
    elsif type == Constant::QUESTION_TYPE_NAMES[:voice_input]  #语音输入题
      branch_question_types = type
      options = que.scan(/\{\{[^\{\{]*\}\}/)[0].to_s.scan(/(?<=\{\{).*(?=\}\})/).to_a[0]
      answer =options
      #content = que.gsub(/\{\{[^\{\{]*\}\}/,"[[text]]")
      content = que.gsub(/\{\{[^\{\{]*\}\}/,"")
      branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
                           :options => options, :answer => answer}
    elsif type == Constant::QUESTION_TYPE_NAMES[:zonghe] #综合题
      tmp = que.to_s.split(%r{\n\s*})
      tmp.each do |e|
        result = distinguish_question_types excel="", e, line=""
        if result[:que_tpye] == -2
          content = content + e
        else
          branch_que =  split_question e, result[:que_tpye]
          branch_questions << {:branch_content => branch_que[:content], :branch_question_types => branch_que[:question_types],
                               :options => branch_que[:branch_questions][0][:options], :answer => branch_que[:branch_questions][0][:answer]}
        end
      end
    elsif type == Constant::QUESTION_TYPE_NAMES[:drag]     #拖拽题
      branch_question_types = type
      c = 0
      que.scan(/\[\[[^\[\[]*\]\]/).to_a.each  do  |e|
        e = e.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s
        options = options + ";||;" if c > 0
        options = options + e
        c = c +1
      end
      answer = options
      content = que.gsub(/\[\[[^\[\[]*\]\]/,"[[text]]")
      branch_questions << {:branch_content => branch_content, :branch_question_types => branch_question_types,
                           :options => options, :answer => answer}
    elsif type == Constant::QUESTION_TYPE_NAMES[:input]    #填空题
      branch_question_types = type
      c = 0
      que.scan(/\(\([^\(\(]*\)\)/).to_a.each  do  |e|
        e = e.scan(/(?<=\(\().*(?=\)\))/).to_a[0].to_s
        options = options + ";||;" if c > 0
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
  def import_data all_round_questions, course_id, chapter_id, path, round_id
    all_round_questions.each do |e|
      excel = e[:excel].to_s
      round_name = e[:round].to_s
      round_score = e[:round_score].to_i
      round_time = e[:round_time].to_i
      time_correct_percent = e[:time_correct_percent].to_i
      blood = e[:blood].to_i
      questions = e[:questions]

      course = Course.find_by_id(course_id)
      Round.transaction do
        if round_id == nil
          round = Round.create!(:chapter_id => chapter_id, :course_id => course.id, :name => round_name,
                             :max_score => course.max_score, :time_ratio => course.time_ratio, 
                             :round_time => course.round_time, :blood => course.blood)
        # round = Round.create(:chapter_id => chapter_id, :course_id => course_id, :name => round_name)
        else
          round = Round.find_by_id(round_id)
          round.update_attributes(:name => round_name)
        end  
        p round.id
        update_round_data round, round_score, round_time, time_correct_percent, blood

        one_json_question = []
        questions.each do |x|
          result = split_question x[:que], x[:type]
          if x[:card_name].size != 0
            cardbag_tag = CardbagTag.find_by_course_id_and_name(course_id,x[:card_types])
            if cardbag_tag.nil?
              cardbag_tag = CardbagTag.create(:course_id => course_id, :name => x[:card_types].to_s, :types => Constant::TAG_TYPE_NAME[:system])
            end
            knowledge_card = KnowledgeCard.create(:name => x[:card_name].to_s, :description => x[:card_description].to_s, :course_id => course_id, :types => 1)
            if !knowledge_card.nil?
              CardTagRelation.create(:course_id => course_id, :knowledge_card_id => knowledge_card.id, :cardbag_tag_id => cardbag_tag.id)
              question = Question.create(:knowledge_card_id => knowledge_card.id, :content => result[:content], :types => result[:question_types], :round_id => round.id, :full_text => x[:que] )
            end
          else
            question = Question.create(:content => result[:content], :types => result[:question_types], :round_id => round.id, :full_text => x[:que] )
          end
          result[:branch_questions].each do |i|
            BranchQuestion.create(:question_id => question.id, :branch_content => i[:branch_content], :types => i[:branch_question_types], :options => i[:options], :answer => i[:answer] )
          end
        end

        questions = round.questions

        questions.each do |e|
          branch_ques = ""
          branch_questions = e.branch_questions
          c = 0
          branch_questions.each do |y|
            branch_ques = branch_ques + "," if c > 0
            branch_ques = branch_ques + "{\"branch_question_id\":#{y.id}, \"branch_content\":\"#{y.branch_content}\",\"branch_question_types\":#{y.types}, \"options\":\"#{y.options}\",\"answer\":\"#{y.answer}\"}"
            c = c + 1
          end
          if e.knowledge_card_id != nil
            knowledge_card = KnowledgeCard.find(e.knowledge_card_id)
            que = "{\"question_id\":#{e.id},\"content\":\"#{e.content}\",\"question_types\":#{e.types},\"branch_questions\": [#{branch_ques}],\"card_id\":#{knowledge_card.id},\"card_name\": \"#{knowledge_card.name}\", \"description\": \"#{knowledge_card.description}\",\"card_types\" : \"#{knowledge_card.types}\"}"
          else
            que = "{\"question_id\":#{e.id},\"content\":\"#{e.content}\",\"question_types\":#{e.types},\"branch_questions\": [#{branch_ques}],\"card_id\":,\"card_name\": \"\", \"description\": \"\",\"card_types\" : \"\"}"
          end

          one_json_question << que
        end

        question_total = Question.where("round_id=#{round.id}").count
        p "question_total#{question_total}"
        if question_total%2 == 0
          question_total = question_total%2
        else
          question_total = (question_total+1)/2
        end
        p "question_total#{question_total}"
        str = ""
        str = str + "course = {\"course_id\" : #{course_id},\n  \"chapter_id\" : #{chapter_id},\n
        \"round_id\" : #{round.id},\n \"round_time\" : \"#{round.round_time}\",\n \"question_total\":#{question_total},
        \"round_score\" : #{round.max_score},  \"percent_time_correct\" : #{round.time_ratio},\n
        \"blood\" : #{round.blood},\"questions\" :["
        tag = 0
        one_json_question.each do |e|
          str = str + "\n,\n" if tag > 0
          str = str + e
          tag = tag + 1
        end
        str = str + "]}"
        
        File.open("#{path}/questions.js", 'wb') do |f|
          f.write(str)
        end

        course_dir = "#{Rails.root}/public/qixueguan/Course_#{course.id}"
        Dir.mkdir course_dir if !File.directory? course_dir
        chapter_dir = course_dir + "/Chapter_#{chapter_id}"
        Dir.mkdir chapter_dir if !File.directory? chapter_dir
        round_dir = chapter_dir + "/Round_#{round.id}"
        Dir.mkdir round_dir if !File.directory? round_dir
        FileUtils.mv "#{path}/questions.js", round_dir
        dir = File.basename(excel,".xls")
        resource_dir = "#{path}/#{dir}"
        if Dir.exist? resource_dir
          files = []
          Dir.entries(resource_dir).each do |sub|
            files << sub if File.file?("#{resource_dir}/#{sub}") if sub != '.' && sub != '..'
          end
          files.each do |file|
            FileUtils.mv "#{resource_dir}/#{file}", round_dir
          end
        end
        File.delete "#{chapter_dir}/Round_#{round.id}.zip" if File.exist? "#{chapter_dir}/Round_#{round.id}.zip"
        Archive::Zip.archive("#{chapter_dir}/Round_#{round.id}.zip", round_dir)
        round.update_attributes(:status => Constant::VARIFY_STATUS[:not_verified])
      end  
    end
  end

  #更新关卡基础数据
  def update_round_data round, round_score, round_time, time_correct_percent, blood
    if round_score != 0
      round.update_attributes(:max_score => round_score)
    end
    if round_time != 0
      round.update_attributes(:round_time => round_time)
    end
    if time_correct_percent != 0
      round.update_attributes(:time_ratio => time_correct_percent)
    end
    if blood != 0
      round.update_attributes(:blood => blood)
    end
  end

end
