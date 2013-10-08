#encoding: utf-8
class User < ActiveRecord::Base
  has_many :user_course_relations
  has_many :friends
  require 'mini_magick'
  validates :email, :uniqueness => {:message => "this email has been regisited"}
  TYPES = {           #用户类型
    :ADMIN => 0,
    :NORMAL => 1
  }


  def encrypt_password(pwd)
    self.password = Digest::SHA2.hexdigest(pwd)
  end

   def self.upload_img(img_url,user_id,folder_name)
    path = "#{Rails.root}/public"
    dirs=["/#{folder_name}","/#{user_id}"]
    dirs.each_with_index {|dir,index| Dir.mkdir path+dirs[0..index].join   unless File.directory? path+dirs[0..index].join }
    file=img_url.original_filename
    filename="#{dirs.join}/img_#{user_id}."+ file.split(".").reverse[0]
    File.open(path+filename, "wb")  {|f|  f.write(img_url.read) }
    temp_file = img_url.tempfile
    unless !File.exist?(temp_file.path) || temp_file.nil?
      temp_file.close
      temp_file.unlink
    end
    return filename
  end

end
