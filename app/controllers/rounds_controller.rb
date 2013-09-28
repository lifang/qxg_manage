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

  private

  def get_course_chapter
    @course = Course.find_by_id params[:course_id]
    @chapter = Chapter.find_by_id params[:chapter_id]
  end
end