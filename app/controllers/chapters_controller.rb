class ChaptersController < ApplicationController
  before_filter :sign?
  before_filter :get_course

  def index
    @chapters = @course.chapters
  end

  def new
    @chapter = @course.chapters.new
  end
  
  def create
    @chapter = @course.chapters.create(params[:chapter])
    if @chapter.save
      redirect_to course_chapters_path(@course.id)
    else
      render :new
    end
  end

  def edit
    @chapter = Chapter.find_by_id(params[:id])
  end

  def update
    @chapter = Chapter.find_by_id(params[:id])
    if @chapter.update_attributes(params[:chapter])
      redirect_to course_chapters_path(@course.id)
    else
      render :edit
    end
  end

  def destroy
    @chapter = Chapter.find_by_id(params[:id])
    @chapter.destroy
    redirect_to course_chapters_path(@course.id)
  end

  private
  def get_course
    @course = Course.find_by_id(params[:course_id])
  end

end