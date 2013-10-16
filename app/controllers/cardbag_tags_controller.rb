#encoding: utf-8
class CardbagTagsController < ApplicationController
  before_filter :sign?, :get_course

  def index
    @tags = CardbagTag.system.where(:course_id => @course.id).paginate(:per_page => 5, :page => params[:page])
    respond_to do |f|
      f.html
      f.js {render :search}
    end
  end

  def new
    @tag = CardbagTag.new
  end

  def create
    @tag = @course.cardbag_tags.create(params[:cardbag_tag])
    if @tag.save
      @notice = "添加成功"
      render :success
    else
      @notice = "添加失败！\\n #{@tag.errors.messages.values.flatten.join("<\\n>")}"
      render :new
    end
  end

  def edit
    @tag = CardbagTag.find_by_id(params[:id])
  end

  def update
    @tag = CardbagTag.find_by_id(params[:id])
    if @tag.update_attributes(params[:cardbag_tag])
      @notice = "更新成功"
      render :success
    else
      @notice = "创建失败！\\n #{@tag.errors.messages.values.flatten.join("<\\n>")}"
      render :edit
    end
  end

  def destroy
    @tag = CardbagTag.find_by_id(params[:id])
    @tag.destroy
    flash[:notice] = "删除成功"
    redirect_to course_cardbag_tags_path(@course.id)
  end

  #搜索标签
  def search
    @tags = CardbagTag.system.where(:course_id => @course.id).where("name like (?)", "%#{params[:tag_name].gsub(/[%_]/){|x| '\\' + x}}%" ).paginate(:per_page => 5, :page => params[:page])
  end
 
  private
  def get_course
    @course = Course.find_by_id(params[:course_id])
  end

end