#encoding: utf-8
class KnowledgeCard < ActiveRecord::Base
  include Constant
  require "fileutils"
  belongs_to :course
  has_many :user_cards_relations
  has_many :card_tag_relations
  has_many :cardbag_tags, :through => :card_tag_relations
  has_many :questions
  SIZE = 30
  IMG_PATH = "/public/uploads/kcards/%d/"
  IMG_REAL_PATH = "/uploads/kcards/%d/"
  def system_tag
    self.cardbag_tags.joins(:card_tag_relations).where(:types => TAG_TYPE_NAME[:system]).where("card_tag_relations.user_id is null").map(&:name).join("、")
  end

  def upload_file(file)
    img_parent_path = Rails.root.to_s + IMG_PATH % self.id
    img_real_parent_path = IMG_REAL_PATH % self.id
    FileUtils.mkdir_p(img_parent_path) unless Dir.exists?(img_parent_path)
    file_name = random_file_name(file.original_filename)
    file_extension = File.extname(file.original_filename)
    filename = file_name + file_extension
    File.open(img_parent_path + filename, "wb")  {|f| f.write(file.read) }
    img = MiniMagick::Image.open img_parent_path + filename,"rb"
    #    SIZE.each do |size|
    new_file = "#{img_parent_path + file_name}_#{SIZE}"+ file_extension
    resize = SIZE > img["width"] ? img["width"] : SIZE
    height = img["height"].to_f/img["width"].to_f > 5.0/6 ?  250 : resize
    img.run_command("convert #{img_parent_path + filename}  -resize #{resize}x#{height} #{new_file}")
    #    end
    return (img_real_parent_path +  "#{file_name}_#{SIZE}"+ file_extension)
  end


  def random_file_name(file_name)
    name = File.basename(file_name)
    return (Digest::SHA1.hexdigest(Time.now.to_s + name))[0..20]
  end

end
