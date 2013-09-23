#encoding: utf-8
class RoundsController < ApplicationController
  before_filter :sign?, :get_course_chapter
  
  def index
    @rounds = Round.where({:course_id => params[:course_id], :chapter_id => params[:chapter_id]})
  end

  def new
    @round = Round.new
  end

  def create
    @round = @chapter.rounds.create(params[:round].merge({:course_id => @course.id}))
    if @round.save
      redirect_to course_chapter_rounds_path(@chapter.id, @course.id)
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
      redirect_to course_chapter_rounds_path(@chapter.id, @course.id)
    else
      render :edit
    end
  end

  def destroy
    @round = Round.find_by_id params[:id]
    @round.destroy
    redirect_to course_chapter_rounds_path(@chapter.id, @course.id)
  end

  private

  def get_course_chapter
    @course = Course.find_by_id params[:course_id]
    @chapter = Chapter.find_by_id params[:chapter_id]
  end
end