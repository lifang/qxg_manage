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

  def search_single_course      #查询单个课程
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
    courses = UserCourseRelation.find_by_sql("select c.id id, c.name name, c.press press, ucr.gold gold, ucr.level level,
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
    cid = params[:cid].to_i
    props = Prop.where(["course_id = ?", cid])
    if props
      render :json => props
    else
      render :json => "error"
    end
    
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
    sp = UserPropRelation.find_by_user_id_and_prop_id(uid, pid)
    render :json => sp
  end

  def achieve_points_ranking  #成就点数排行，根据user_id 和course_id ,查出包括自己跟好友的成就排行
    user_id = params[:uid]
    course_id = params[:course_id]
    friend_ids = Friend.find_all_by_user_id(user_id).map(&:friend_id) << user_id

    achieve_points_arr = UserCourseRelation.joins(:user => :friends).where(:user_id => friend_ids, :course_id => course_id)
    .select("distinct user_course_relations.user_id as user_id, users.name as uname, user_course_relations.achieve_point as achieve_point, users.img as logo")
    .order("achieve_point desc")

    achieve_points_arr.each{|achieve| achieve[:self] = (achieve.user_id == user_id.to_i ? 1 : 0)}
    render :json => achieve_points_arr
  end

  def everyday_tasks    #每日任务
    uid = params[:uid].to_i
    cid = params[:cid].to_i
    et = EverydayTask.find_by_user_id_and_course_id(uid, cid)
    if et.nil?
      render :json => "error"
    else
      render :json => et.get_login_day
    end
  end

  def set_task_day  #修改连续天数
    uid = params[:uid].to_i
    cid = params[:cid].to_i
    et = EverydayTask.find_by_user_id_and_course_id(uid, cid)
    if et.nil?
      render :json => "error"
    else
      task_time = et.updated_at.nil? || et.updated_at == "" ? 0 : et.updated_at.strftime("%Y%m%d").to_i
      now_time = Time.now.strftime("%Y%m%d").to_i
      if now_time - task_time == 1
        et.update_attribute("day", et.day+1)
      else
        et.update_attribute("day", 1)
      end
      render :json => et.day
    end
  end

  #关联微博
  def bind_weibo
    #参数 uid, weibo_id, weibo_time,根据uid更新weibo_id和weibo_time
    user = User.find_by_id(params[:uid])
    if user && user.update_attributes({:weibo_id => params[:weibo_id], :weibo_time => params[:weibo_time]})
      render :json => "success"
    else
      render :json => "error"
    end
  end

  #添加通讯录、微博好友
  def add_friend
    #参数 uid, friend_id
    f1 = Friend.create({:user_id => params[:uid], :friend_id => params[:friend_id]})
    f2 = Friend.create({:user_id => params[:friend_id], :friend_id => params[:uid]})
    render :json => { :msg => f1&&f2 ? "success" : "error"}
  end

  #返回通讯录好友
  def contact_list
    #参数 uid, phone_ids逗号分隔
    phones = params[:phones].split(",")
    in_app_user_phones = User.where(:phone => phones)
    not_in_app_phones = phones - in_app_user_phones.map(&:phone)
    user_phone_ids = in_app_user_phones.map(&:id)
    friend_ids = Friend.where(:user_id => params[:uid]).map(&:friend_id)
    added_friend_ids = user_phone_ids & friend_ids
    can_add_friend_ids = user_phone_ids - friend_ids
    render :json => {:added_phone_friends => User.where(:id => added_friend_ids),
      :can_add_phone_friends => User.where(:id => can_add_friend_ids), :not_opened_phones => not_in_app_phones}
  end

  #返回微博好友
  def weibo_list
    #参数 uid， weibo_ids用逗号分隔
    weibo_ids = params[:weibo_id].split(",").map(&:to_i)
    in_app_weibo_users = User.where(:weibo_id => weibo_ids)
    not_in_app_weibo_ids = weibo_ids - in_app_weibo_users.map(&:weibo_ids)
    weibo_user_ids = in_app_weibo_users.map(&:id)
    friend_ids = Friend.where(:user_id => params[:uid]).map(&:friend_id)
    added_friend_ids = weibo_user_ids & friend_ids
    can_add_friend_ids = weibo_user_ids - friend_ids
    render :json =>{:added_weibo_friends => User.where(:id => added_friend_ids),
      :can_add_weibo_friends => User.where(:id => can_add_friend_ids), :not_opened_weibo_ids => not_in_app_weibo_ids}
  end
  
end