module ImageHandler
  def remove_image_after_deleted
    img_full_path_str = (Rails.root.to_s + "/public" + self.img.url)
    img_thumbnail_full_path_str = (Rails.root.to_s + "/public" + self.img.thumb.url)
    File.delete img_full_path_str if File.exists?(img_full_path_str)
    File.delete img_thumbnail_full_path_str if File.exists?(img_thumbnail_full_path_str)
  end
end