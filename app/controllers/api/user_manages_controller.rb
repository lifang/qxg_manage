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

  def everyday_tasks    #每日任务
     uid = params[:uid].to_i
     cid = params[:cid].to_i
     et = EverydayTask.find_by_user_id_and_course_id(uid, cid)
     if et.nil?
       render :json => "error"
     else
       task_time = et.updated_at.nil? || et.updated_at == "" ? 0 : et.updated_at.strftime("%Y%m%d").to_i
       now_time = Time.now.strftime("%Y%m%d").to_i
       if now_time - task_time > 1
         et.update_attribute("day", 0)
       end
       render :json => et.day
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
end