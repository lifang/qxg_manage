#encoding: utf-8
module CoursesHelper

  def verify_button(model)
    model.status==1 ?
      (link_to "已审核", "#", :class => "verified"):
      (link_to "审核", "/#{model.class.name.downcase.pluralize}/#{model.id}/verify",:remote => "true", :id => "#{model.class.name.downcase}_#{model.id}", :class => "green_btn", :style=>"padding: 0;")
  end

  def name_strip(name)
    name = name.strip
  end
end