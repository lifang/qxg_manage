class KnowledgeCardsController < ApplicationController
  include ActionView::Helpers::SanitizeHelper
  before_filter :sign?, :get_course, :except => [:md_to_html]

  def index
    
  end

  def edit
    @knowledge_card = KnowledgeCard.find_by_id(params[:id])
    img_folder = Rails.root.to_s + (KnowledgeCard::IMG_PATH % @knowledge_card.id)
    @images_paths = []
    Dir.foreach(img_folder) do |file|
      if !File.directory?(file) && file.include?("_"+ KnowledgeCard::SIZE.to_s)
        @images_paths << ((KnowledgeCard::IMG_REAL_PATH % @knowledge_card.id) + file)
      end
    end if Dir.exists?(img_folder)
    @question = Question.find_by_id params[:question_id]
  end

  def update
    @knowledge_card = KnowledgeCard.find_by_id(params[:id])
    if @knowledge_card.update_attributes(params[:knowledge_card])
      render :success
    else
      render :error
    end
  end

  #markdown to html
  def md_to_html
   content = params[:content]
   render :text => format(content)
  end

  #knowledge card upload files
  def upload_kcard
    #kc_photo, kcard_id
    @knowledge_card = KnowledgeCard.find_by_id(params[:kcard_id])
    file = params[:kc_photo]
    @img_path = @knowledge_card.upload_file(file)
  end

  
  private
  def get_course
    @course = Course.find_by_id(params[:course_id])
  end
  
end