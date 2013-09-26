#encoding: utf-8
module CoursesHelper

  def verify_button(model)
    model.status==1 ?
      (link_to "已审核", "#", :class => "verified")
      :
      (link_to "审核", "/#{model.class.name.downcase.pluralize}/#{model.id}/verify",:remote => "true", :id => "#{model.class.name.downcase}_#{model.id}", :class => "wait_verify")
  end
end