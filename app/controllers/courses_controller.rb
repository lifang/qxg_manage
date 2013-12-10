#encoding: utf-8
class CoursesController < ApplicationController
  before_filter :sign?
  def index
    @courses = Course.paginate(:per_page =>9, :page => params[:page])
  end

  def new
    @course = Course.new
  end

  def edit
    @course = Course.find_by_id params[:id]
  end

  def create
    params[:course][:name] =  name_strip(params[:course][:name])
    @course = Course.create(params[:course])
    if @course.save
      @notice = "添加成功！"
      render :success
    else
      @notice = "添加失败！\\n #{@course.errors.messages.values.flatten.join("<\\n>")}"
      render :new
    end
  end

  def update
    @course = Course.find_by_id params[:id]
    params[:course][:name] =  name_strip(params[:course][:name])
    if @course.update_attributes(params[:course])
      @course.status = VARIFY_STATUS[:not_verified] if @course.status == VARIFY_STATUS[:verified]
      @course.save
      @notice = "更新成功！"
      render :success
    else
      @notice = "更新失败！\\n #{@course.errors.messages.values.flatten.join("<\\n>")}"
      render :edit
    end
  end
  #TODO
  def destroy
    @course = Course.find_by_id params[:id]
    course_url = "#{Rails.root}/public/qixueguan/Course_#{@course.id}"
    FileUtils.remove_dir course_url if Dir.exist? course_url
    @course.destroy    
    flash[:notice] = "删除成功"
    redirect_to courses_path
  end

  #审核
  def verify
    @course = Course.find_by_id params[:id]
    Course.transaction do
      if @course.update_attribute(:status, true)
        @notice = "审核成功"
        #计算每一等级需要的经验值
        chapters = @course.chapters
        course_rounds_count = chapters.inject(0){|sum, chapter| sum += (chapter.rounds_count.to_i)}
        exp_arr  = update_course_level(course_rounds_count)
       
        exp_arr.each_with_index do |experience, index|
          lv = LevelValue.find_by_course_id_and_level(@course.id, index + 1)
          if lv
            lv.update_attribute(:experience_value, experience)
          else
            LevelValue.create({:course_id => @course.id, :level => index + 1, :experience_value =>  experience})
          end
         
        end

      else
        @notice = "审核失败"
      end
    end
  end
end
