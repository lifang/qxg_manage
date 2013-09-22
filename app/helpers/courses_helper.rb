#encoding: utf-8
module CoursesHelper

  def verify_button(course)
    course.status==1 ?
      (link_to "已审核", "#", :class => "verified")
      :
      (link_to "审核", verify_course_path(course.id),:remote => "true", :id => "course_#{course.id}", :class => "wait_verify")
  end
end