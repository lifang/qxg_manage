#encoding: utf-8
class Api::UserManagesController < ActionController::Base
  
  def search_course     #查询课程
    name = params[:search_name].strip.gsub(/[%_]/){|x|'\\' + x}
    uid = params[:uid].to_i
    courses = Course.find_by_sql("select c.id,c.name,c.press,c.description,c.round_count,c.types
                                   from courses c where name like '%#{name}%'")
    selected_courses = UserCourseRelation.where(["user_id = ? ", uid]).map(&:course_id)
    a = []
    Course::TYPES.each do |k, v|
      a << v
    end
    render :json => {:c => courses, :sc => selected_courses, :type_name => a}
  end

  def search_single_course
    uid = params[:uid].to_i
    cid = params[:course_id]
    course = Course.select("id, name, press, description, round_count, types").find_by_id(cid.to_i)
    type_name = Course::TYPES[course.types]
    flag = UserCourseRelation.find_by_user_id_and_course_id(uid, cid).nil?
    a = flag == true ? 0 : 1
    render :json => {:course => course, :type_name => type_name, :flag => a}
  end

  def selected_courses  #用户已选择的课程
    uid = params[:uid].to_i
    courses = UserCourseRelation.find_by_sql("select c.id id, c.name name, c.press press, 
                                              c.description description, c.types types, c.round_count round_count
                                              from user_course_relations ucr
                                              inner join courses c on ucr.course_id=c.id
                                              where ucr.user_id=#{uid}")
    courses.each do |c|
      c.types = Course::TYPES[c.types]
    end
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

  def achieve_points_ranking  #成就点数排行，根据user_id 和course_id ,查出包括自己跟好友的成就排行
    user_id = params[:user_id]
    course_id = params[:course_id]
    friend_ids = Friend.find_all_by_user_id(user_id).map(&:friend_id) << user_id

    achieve_points_arr = UserCourseRelation.joins(:user => :friends).where(:user_id => friend_ids, :course_id => course_id)
    .select("user_course_relations.user_id as user_id, users.name as uname, user_course_relations.achieve_point as achieve_point, users.img as logo")
    .order("achieve_point desc")
    achieve_points_arr.each{|achieve| achieve[:self] = (achieve.user_id == user_id.to_i ? 1 : 0)}
    render :json => achieve_points_arr
  end

  def everyday_tasks    #每日任务

  end
end