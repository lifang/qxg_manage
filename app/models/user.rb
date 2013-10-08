#encoding: utf-8
class User < ActiveRecord::Base
  require 'mini_magick'
  validates :email, :uniqueness => {:message => "this email has been regisited"}
  TYPES = {           #用户类型
    :ADMIN => 0,
    :NORMAL => 1
  }


  def encrypt_password(pwd)
    self.password = Digest::SHA2.hexdigest(pwd)
  end

   def self.upload_img(img_url,user_id,pic_types,pics_size)
    path = "#{Rails.root}/public"
    dirs=["/#{pic_types}","/#{user_id}"]
    dirs.each_with_index {|dir,index| Dir.mkdir path+dirs[0..index].join   unless File.directory? path+dirs[0..index].join }
    file=img_url.original_filename
    filename="#{dirs.join}/img#{user_id}."+ file.split(".").reverse[0]
    File.open(path+filename, "wb")  {|f|  f.write(img_url.read) }
    img = MiniMagick::Image.open path+filename,"rb"
    pics_size.each do |size|
      new_file="#{dirs.join}/img#{user_id}_#{size}."+ file.split(".").reverse[0]
      resize = size > img["width"] ? img["width"] : size
      height = img["height"].to_f*resize/img["width"].to_f > 345 ?  345 : resize
      img.run_command("convert #{path+filename}  -resize #{resize}x#{height} #{path+new_file}")
    end
    return filename
  end

end
