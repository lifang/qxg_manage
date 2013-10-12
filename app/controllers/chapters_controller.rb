#encoding: utf-8
require 'rubygems'
require 'archive/zip'
class ChaptersController < ApplicationController
  before_filter :sign?
  before_filter :get_course, :except => [:verify]

  def index
    @chapters = @course.chapters
  end

  def new
    @chapter = @course.chapters.new
  end
  
  def create
    @chapter = @course.chapters.create(params[:chapter])
    if @chapter.save
      flash[:notice] = "创建成功！"
      render :success
    else
      @notice = "创建失败！ #{@chapter.errors.messages.values.flatten.join("<br/>")}"
      render :new
    end
  end

  def edit
    @chapter = Chapter.find_by_id(params[:id])
  end

  def update
    @chapter = Chapter.find_by_id(params[:id])
    if @chapter.update_attributes(params[:chapter])
      flash[:notice] = "更新成功！"
      render :success
    else
      @notice = "更新失败！ #{@chapter.errors.messages.values.flatten.join("<br/>")}"
      render :edit
    end
  end

  #上传文件
  def uploadfile
    zipfile = params[:zip]
    base_url = "#{Rails.root}/public/qixueguan/tmp"
    if !zipfile.nil?
      user_id = 121
      time_now = Time.now().to_s.slice(0,19).gsub(/\:/,'-')
      if !File.directory? "#{base_url}/user_#{user_id}"
        Dir.mkdir "#{base_url}/user_#{user_id}"
      end

      filename = zipfile.original_filename.split(".")
      zip_dir = time_now.slice(0,10) + "_" + time_now.slice(11,8)
      zipfile.original_filename = zip_dir + "." +filename[1]
      File.open(Rails.root.join("public", "qixueguan/tmp/user_#{user_id}", zipfile.original_filename), "wb") do |file|
        file.write(zipfile.read)
      end

      unzip base_url, user_id, zip_dir
      read_excel base_url ,user_id ,zip_dir
      #read_question_data 121, dir, course_id, chapter_id, round_id

    end

    redirect_to :action => "index"
  end

  #解压压缩包、获取excel文件名和资源目录
  def unzip base_url, user_id, zip_dir
    zip_url = "#{base_url}/user_#{user_id}"

    if !File.directory? "#{zip_url}/#{zip_dir}"
      Dir.mkdir "#{zip_url}/#{zip_dir}"
    end
    begin
      Archive::Zip.extract "#{zip_url}/#{zip_dir}.zip","#{zip_url}/#{zip_dir}"
    rescue
    end
    File.delete "#{zip_url}/#{zip_dir}.zip"
  end

  def read_excel base_url ,user_id ,zip_dir
    path = "#{base_url}/user_#{user_id}/#{zip_dir}"
    excel_files =  []
    resource_dir = []

    #获取excel文件和资源目录
    Dir.entries(path).each do |sub|
      if sub != '.' && sub != '..'
        if File.directory?("#{path}/#{sub}")
          resource_dir << sub.to_s
          #get_file_list("#{path}/#{sub}")
        else
          excel_files << sub.to_s
        end
      end
    end

    #循环每个execl文件
    excel_files.each do |excel|
      p "#{path}/#{excel}"
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
        type = 0
        error_info = ""
        #判断题型
        result = distinguish_question_types que,line
        result.each do |key,val|
          if val.class == Fixnum
            type = val
          else
            error_info = val[0].to_s
          end
        end
        p "#{Question::TYPES[type]} #{error_info} "
        # if 错误信息为空，则开始截取

      end
    end

    #resource_dir.each do |dir|
    #  p dir
    #end
  end

  #识别题型
  def distinguish_question_types que,line
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
    #p que

    #匹配excel回车标记
    result_d = que.scan(%r{\n\s*})
    count_d = result_d.length if result_d.length != 0

    #p que.split(%r{\n\s*}) if double_bracket_d != 0

    if(count_a != 0 || count_b != 0 || count_c != 0)
      p "---------------------------------------------------"
      count_e = 0		#||计数
      count_f = 0		#;;计数
      count_g = 0		#>>计数
      count_h = 0 	#@@计数
      if(count_a != 0 && count_b == 0 && count_c == 0)
        if(result_a.length == 1)
          count_e = result_a[0].scan(/\|\|/).length
          count_f = result_a[0].scan(/\;\;/).length

          if(count_e != 0 && count_f == 0 && (result_a[0].scan(/\>\>/).length) == 0)
            tmp = result_a[0].scan(/(?<=\[\[).*(?=\]\])/).to_a
            tmp = tmp[0].split(/\|\|/)
            tmp.each do |t|
              count_h = count_h + 1 if t.match(/^@@/)
            end
            if(count_h == 1)
              que_tpye = Question::TYPE_NAMES[:single_choice] #单选题
            elsif(count_h > 1)
              que_tpye = Question::TYPE_NAMES[:multiple_choice] #多选题
            else                        error_info
              error_info << "第#{line}行：选择题没有答案"
            end
          elsif(count_e != 0 && count_f == 0)
            tmp = result_a[0].scan(/(?<=\[\[).*(?=\]\])/).to_a
            tmp = tmp[0].split(/\|\|/)
            tmp.each do |t|
              count_g = result_a[0].scan(/\>\>/).length
            end
            if(count_g != 0)
              que_tpye = Question::TYPE_NAMES[:lineup] #连线题

              #if()
              #error_info << "第#{line}行：连线题对应关系不完整"
              #end
            else
              que_tpye = -1 #未知题型
              error_info << "未知题型"
            end
          end
        elsif(count_a > 1)
          if(count_e == 0 && count_f == 0 && result_a[0].scan(/\;\;/).length == 0)
            if(count_d == 0)

              count=0
              result_a.each do |e|
                p e
                if e.scan(/(?<=\[\[).*(?=\]\])/)[0].to_s.scan(/\|\|/).length >= 1
                  count = count + 1
                end
              end
              if count == result_a.length
                c = 0
                result_a.each do |e|
                  p e
                  if e.scan(/(?<=\[\[).*(?=\]\])/)[0].to_s.scan(/\@\@/).length >= 1
                    c = c + 1
                  end
                end
                if c == result_a.length
                  que_tpye = Question::TYPE_NAMES[:fillin] # 完型填空
                else
                  que_tpye = -1 #未知题型
                  error_info << "第#{line}行:完型填空题中有选项没有答案"
                end
              elsif(count == 0)
                que_tpye = Question::TYPE_NAMES[:drag] # 拖拽题
              else
                que_tpye = -1 #未知题型
                error_info << "未知题型"
              end
            else
              que_tpye = Question::TYPE_NAMES[:read_understanding] # 阅读理解
            end
          else
            que_tpye = -1 #未知题型
            error_info << "未知题型"
          end

        end
      elsif(count_b != 0 && count_a == 0 && count_c == 0)
        que_tpye = Question::TYPE_NAMES[:input] #填空题
      elsif(count_c == 1 && count_a == 0 && count_b == 0)
        que_tpye = Question::TYPE_NAMES[:voice_input] #口语题
      end
      p "||total:#{count_e}  ;;total:#{count_f}  >>total:#{count_g}  @@total:#{count_h}"
      p "[[]]total:#{count_a}  (())total:#{count_b}  {{}}total:#{count_c} ENTER total:#{count_d}"
    else
      que_tpye = -1 #未知题型
      error_info << "未知题型"
    end
    result = {"que_tpye" => que_tpye, "error_info" => error_info }
  end

  def destroy
    @chapter = Chapter.find_by_id(params[:id])
    @chapter.destroy
    flash[:notice] = "删除成功"
    redirect_to course_chapters_path(@course.id)
  end

  #审核
  def verify
    @chapter = Chapter.find_by_id params[:id]
    if @chapter.update_attribute(:status, true)
      @notice = "审核成功"
    else
      @notice = "审核失败"
    end
  end

  private
  def get_course
    @course = Course.find_by_id(params[:course_id])
  end

end