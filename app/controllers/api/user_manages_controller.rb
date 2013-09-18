#encoding: utf-8
class Api::UserManagesController < ActionController::Base
  
  def search_course     #查询课程
    name = params[:search_name].strip.gsub(/[%_]/){|x|'\\' + x}
    uid = params[:uid].to_i
    courses = Course.where("name like (%#{name}%)")
    selected_courses = UserCourseRelation.where(["user_id = ? ", uid]).map(&:course_id)
    render :json => {:c => courses, :sc => selected_courses}
  end

  def selected_courses  #用户已选择的课程
    uid = params[:uid].to_i
    courses = UserCourseRelation.find_by_sql("select c.* from user_course_relations ucr
                                              inner join courses c on ucr.course_id=c.id
                                              where ucr.user_id=#{uid}")
    render :json => courses
  end

  def props_list    #道具列表
    props = Props.all
    render :json => props
  end

  def buy_prop      #购买道具
    uid = params[:uid].to_i
    pid = params[:pid].to_i
    pcount = params[:pcount].to_i
    selected_prop = UserPropRelation.find_by_user_id_and_prop_id(uid, pid)
    if selected_prop
      selected_prop.update_attribute("user_prop_num", selected_prop.user_prop_num + pcount)
    else
      UserPropRelation.create(:user_id => uid, :prop_id => pid, :user_prop_num => pcount)
    end
      BuyRecord.create(:user_id => uid, :prop_id => pid, :count => pcount)
      render :json => "success"
  end

  def everyday_tasks    #每日任务

  end
end