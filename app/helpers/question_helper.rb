#encoding: utf-8
module QuestionHelper
  #解压zip题库压缩包
  def unzip zip_url, zip_dir
    if !File.directory? "#{zip_url}/#{zip_dir}"
      Dir.mkdir "#{zip_url}/#{zip_dir}"
    end
    begin
      Archive::Zip.extract "#{zip_url}/#{zip_dir}.zip","#{zip_url}/#{zip_dir}"
      return true
    rescue
      File.delete "#{zip_url}/#{zip_dir}.zip"
      Dir.delete "#{zip_url}/#{zip_dir}"
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

  #判断题目中的双括号（包括(())、[[]]、{{}}）是否成对、及是否存在包含关系 未完成
  def brackets_validate
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
  end

  #识别题型
  def distinguish_question_types excel,que,line
    que_tpye = -1 #题型标记
    error_info = [] #错误信息

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

    p "---------------------------------------------------"
    #  count_e = 0		#||计数
    #  count_f = 0		#;;计数
    #  count_g = 0		#>>计数
    #  count_h = 0 	  #@@计数

    if(count_a != 0 || count_b != 0 || count_c != 0)   #[[]]、(())、{{}}的数量不能都为0
      if count_a == 1 && count_b == 0 && count_c == 0 #当只有一对[[]]时
                                                      #可能题型：选择题、排序题、连线题、
        tmp = result_a[0].to_s.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s
        count_e = tmp.scan(/\|\|/).length
        count_f = tmp.scan(/\;\;/).length
        if(count_e == 0 && count_f == 0) #当选项中没有||和;;分隔符
          que_tpye = -1 #未知题型
          error_info << "文件'#{excel}'第#{line}行：未知题型"
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
          if count == 0
            if d != 0 && d == tmp.split(/\|\|/).length
              g = 0
              tmp.split(/\|\|/).to_a.each do |e|
                e = e.gsub(/file>>>/,"file>;=;").to_s.gsub(/>>/,";=;").split(";=;")
                if e.length != 2
                  g = g + 1
                else
                  #p  e[0].to_s.strip.empty?
                  #p  e[1].to_s.strip.empty?
                  if e[0].gsub(/^||/,"").to_s.strip.empty? || e[1].gsub(/^||/,"").to_s.strip.empty?
                    g = g + 1
                  end
                end
              end

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
      elsif count_a > 1 && count_b == 0 && count_c == 0 && result_d.length == 0  #拖拽题和完形填空题
        tmp = []
        result_a.each do |r|
          tmp << r.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s
        end
        p tmp
        #length = tmp.length - 1
        #(0..length).each do |i|
        #  tmp[i] = tmp[i].to_s.scan(/(?<=\[\[).*(?=\]\])/).to_a[0].to_s
        #end
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
        p result
        #p count_one
        #p count_zero
        if count_one == 0 && count_zero != 0 && count_zero == result.length  #拖拽题
          p "第#{line}行：拖拽题"
        elsif count_zero == 0 && count_one != 0 && count_one == result.length #完型填空题
          result = [] #统计每个选项里的答案数,即@@个数
          tmp.each do |e|
            g = 0 #统计一个选项中的答案个数，即@@个数
            e.gsub(/^\|\|/,"").split("||").each do |x|
              if x.to_s.lstrip.match(/^@@/)
                 g = g + 1
              end
              p "x = " + x if x.to_s.lstrip.match(/^@@/)
            end
            result << g
          end
          p  result
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
            p "第#{line}行：完形填空"
          elsif count_zero != 0 || count_one_more != 0
            error_info << "第#{line}行：完形填空完型填空题中的某个选项没答案或有多个答案"
          end
        else
          error_info << "第#{line}行：完形填空题的每个选项[[……]]中至少有一个必须有'||'或拖拽题的每个选项[[……]]中都不能有'||'"
        end
      #elsif count_a > 1 && count_b == 0 && count_c == 0 && result_d !=  0 #不正确
      #  p "第#{line}行：阅读理解"
      #elsif count_a == 0 && count_b >= 1 && count_c == 0
      #  p "第#{line}行：填空题"
      #elsif count_a == 0 && count_b > 0  && count_c == 0
      #  p "第#{line}行：填空题"
      elsif count_b >= 1 && count_a == 0 && count_c == 0
        que_tpye = Question::TYPE_NAMES[:input] #填空题
      elsif count_c == 1 && count_a == 0 && count_b == 0   # 综合题
        tmp =  que.split(%r{\n\s*})

        tmp.each do |e|
          p distinguish_question_types excel, e, line
        end
        que_tpye = Question::TYPE_NAMES[:read_understanding] # 综合题
      end
     #              que_tpye = Question::TYPE_NAMES[:fillin] # 完型填空
     #       que_tpye = Question::TYPE_NAMES[:voice_input] #口语题
     #      que_tpye = Question::TYPE_NAMES[:drag] # 拖拽题

    else
      que_tpye = -1 #未知题型
      error_info << "第#{line}行：未知题型"
    end
    #p "||total:#{count_e}  ;;total:#{count_f}  >>total:#{count_g}  @@total:#{count_h}"
    p "[[]]total:#{count_a}  (())total:#{count_b}  {{}}total:#{count_c} ENTER total:#{count_d}"
    result = {"que_tpye" => que_tpye, "error_info" => error_info }
  end
end
