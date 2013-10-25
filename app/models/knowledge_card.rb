#encoding: utf-8
class KnowledgeCard < ActiveRecord::Base
  require "fileutils"
  belongs_to :course
  has_many :user_cards_relations
  has_many :card_tag_relations
  has_many :cardbag_tags, :through => :card_tag_relations
  SIZE = 30
  IMG_PATH = "/public/uploads/kcards/%d/"
  def system_tag
    self.cardbag_tags.joins(:card_tag_relations).where(:types => CardbagTag::TYPE_NAME[:system]).where("card_tag_relations.user_id is null").map(&:name).join("、")
  end

  def upload_file(file)
    img_parent_path = Rails.root + IMG_PATH % self.id 
    FileUtils.mkdir_p(img_parent_path) unless Dir.exists?(img_parent_path)
    file_name = random_file_name(file.original_filename)
    file_extension = File.extname(file_name)
    filename = file_name + "." + file_extension
    File.open(img_parent_path + filename, "wb")  {|f| f.write(file.read) }
    img = MiniMagick::Image.open img_parent_path + filename,"rb"
    #    SIZE.each do |size|
    new_file = "#{img_parent_path}_#{SIZE}."+ file_extension
    resize = SIZE > img["width"] ? img["width"] : SIZE
    height = img["height"].to_f/img["width"].to_f > 5.0/6 ?  250 : resize
    img.run_command("convert #{img_parent_path + filename}  -resize #{resize}x#{height} #{img_parent_path + new_file}")
    #    end
    return (img_parent_path + new_file)
  end


  def random_file_name(file_name)
    name = File.basename(file_name)
    return (Digest::SHA1.hedigest Time.now.to_s + name)[0..20]
  end

end
