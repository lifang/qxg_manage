#encoding: utf-8
class UsersController < ApplicationController
  before_filter :sign?

  def index
    @users = User.signed_user.paginate(:per_page => 20, :page => params[:page])
  end

  def show
    @user = User.includes(:courses, :props).find_by_id params[:id]
    @courses = Course.joins(:user_course_relations).where("user_course_relations.user_id = ?", @user.id).select("courses.name cname,courses.id cid, user_course_relations.level,user_course_relations.gold,
    user_course_relations.achieve_point, (user_course_relations.cardbag_count - user_course_relations.cardbag_use_count) as cardbag_left_count")
  end
end