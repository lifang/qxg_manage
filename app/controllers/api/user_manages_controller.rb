#encoding: utf-8
class Api::UserManagesController < ActionController::Base
  include Constant
  def search_course     #查询课程
    #search_name, uid  已审核
    name = params[:search_name].strip.gsub(/[%_]/){|x|'\\' + x}
    uid = params[:uid].to_i
    courses = Course.find_by_sql("select c.id,c.name,c.press,c.description,c.types,c.img
                                   from courses c where name like '%#{name}%' and status=#{VARIFY_STATUS[:verified]}")
    selected_courses = UserCourseRelation.where(["user_id = ? ", uid]).map(&:course_id)

    course_arr = []
    courses.each{|course|
      course_hash = course.attributes
      chapter = course.chapters.verified[0]
      if chapter
        rounds = chapter.rounds.verified.limit 5
        chapter_hash = chapter.attributes
        chapter_hash[:logo] = chapter.img.thumb.url
        chapter_hash.delete(:img)
        course_hash[:chapter] = chapter_hash
        course_hash[:rounds] = rounds
      end
      course_hash[:logo] = course.img.thumb.url
      course_hash[:types] = COURSE_TYPES[course.types]
      course_hash[:is_new] = selected_courses.include?(course.id) ? 0 : 1
      course_hash.delete(:img)
      course_arr << course_hash
    }

    render :json => {:c => course_arr}
  end

  def search_single_course      #查询单个课程 二维码查询
    #uid, course_id  已审核
    uid = params[:uid].to_i
    cid = params[:course_id]
    selected_courses = UserCourseRelation.where(["user_id = ? ", uid]).map(&:course_id)
    course = Course.select("id, name, press, description, types, img").find_by_id_and_status(cid.to_i, VARIFY_STATUS[:verified])
    if course
      course_hash = course.attributes
      chapter = course.chapters.verified[0]
      if chapter
        rounds = chapter.rounds.verified.limit 5
        chapter_hash = chapter.attributes
        chapter_hash[:logo] = chapter.img.thumb.url
        chapter_hash.delete(:img)
        course_hash[:chapter] = chapter_hash
        course_hash[:rounds] = rounds
      end
      course_hash[:logo] = course.img.thumb.url
      course_hash[:types] = COURSE_TYPES[course.types]
      course_hash[:is_new] = selected_courses.include?(course.id) ? 0 : 1
      course_hash.delete(:img)
      message = "success"
    else
      message = "course_not_found"
    end
    #flag = UserCourseRelation.find_by_user_id_and_course_id(uid, cid).nil?

    render :json => {:course => course_hash || {}, :message => message}
  end

  def selected_courses  #课程中心，所有课程以及 用户已选择的课程标志is_new
    #uid
    uid = params[:uid].to_i
    courses = Course.verified #已审核
    selected_courses = UserCourseRelation.where(["user_id = ? ", uid]).map(&:course_id).uniq
    course_arr = []
    courses.each do |c|
      course_hash = c.attributes
      chapter = c.chapters.verified[0]
      if chapter
        rounds = chapter.rounds.verified.limit 5
        chapter_hash = chapter.attributes
        chapter_hash[:logo] = chapter.img.thumb.url
        chapter_hash.delete(:img)
        course_hash[:chapter] = chapter_hash
        course_hash[:rounds] = rounds
      end
      course_hash[:logo] = c.img.thumb.url
      course_hash[:types] = COURSE_TYPES[c.types]
      course_hash[:is_new] = selected_courses.include?(c.id) ? 0 : 1
      course_hash.delete(:img)
      course_arr << course_hash
    end
    render :json => course_arr
  end

  #返回请求下载剩下关卡的下载信息，course_id, chapter_id, round_id
  def return_round_ids
    #uid, course_id, chapter_id, round_id 已审核
    ucr = UserCourseRelation.find_by_user_id_and_course_id(params[:uid], params[:course_id])
    if ucr
      chapter = Chapter.find_by_id params[:chapter_id]
      if params[:round_id].to_i == 0
        rounds = chapter.rounds.verified.limit 5
      else
        rounds = chapter.rounds.where("id > ?", params[:round_id].to_i).verified.limit 5
      end
      
      render :json => {:message => "success", :round_ids => rounds.map(&:id)}
    else
      render :json => {:message => "error"}
    end
  end

  def buy_prop      #购买道具
    #uid,course_id,pid,pcount
    uid, pid, course_id, pcount = params[:uid].to_i, params[:pid].to_i, params[:course_id].to_i, params[:pcount].to_i

    UserPropRelation.transaction do
      begin
        prop = Prop.find_by_id pid
        ucr = UserCourseRelation.find_by_user_id_and_course_id(uid, course_id)
        ucr.update_attribute(:gold, ucr.gold - prop.price * pcount) if ucr
        BuyRecord.create({:user_id => params[:uid], :prop_id => params[:prop_id], :count => pcount, :gold => prop.price * pcount, :types => PROP_TYPE_NAME[:buy]}) if prop
        selected_prop = UserPropRelation.find_by_user_id_and_prop_id(uid, pid)
        if selected_prop
          selected_prop.update_attribute("user_prop_num", selected_prop.user_prop_num + pcount)
        else
          UserPropRelation.create(:user_id => uid, :prop_id => pid, :user_prop_num => pcount)
        end
        message = "success"
      rescue
        message = "error"
      end

      render :json => {:message => message}
    end
  end

  def achieve_points_ranking  #成就点数排行，根据user_id 和course_id ,查出包括自己跟好友的成就排行
    #uid, course_id
    user_id = params[:uid]
    course_id = params[:course_id]
    friend_ids = Friend.find_all_by_user_id(user_id).map(&:friend_id) << user_id

    achieve_points_arr = UserCourseRelation.joins(:user => :friends).where(:user_id => friend_ids, :course_id => course_id)
    .select("distinct user_course_relations.user_id as user_id, users.name as uname, user_course_relations.achieve_point as achieve_point, users.img as logo")
    .order("achieve_point desc")

    achieve_points_arr.each{|achieve| achieve[:self] = (achieve.user_id == user_id.to_i ? 1 : 0)}
    user_achieve = Achieve.where(:user_id=>params[:uid],:course_id=>params[:course_id]).select(:achieve_data_id).order("created_at desc").map(&:achieve_data_id).uniq
    render :json => {:rank =>achieve_points_arr, :user_achieve => user_achieve}
  end

  def everyday_tasks    #每日任务选题
    #uid, course_id
    response.header['Access-Control-Allow-Origin'] = '*'
    response.header['Content-Type'] = 'text'
    status = 0
    wrong_questions = Question.includes(:branch_questions).joins(:user_mistake_questions).where(:user_mistake_questions => {:user_id => params[:uid], :course_id => params[:course_id]}).select("questions.*")
    questions = []
    if wrong_questions.length < 20
      round_questions = Question.includes(:branch_questions).joins(:round => :round_scores).where(:round_scores =>{:user_id => params[:uid]}, :rounds => {:course_id => params[:course_id]}).select("questions.*").order("round_scores.updated_at asc")
      if(wrong_questions + round_questions).length < 20
        #TODO
        questions = wrong_questions

        status = 1 #用户暂无任务，请先完成更多的关卡挑战
      else
        rs_question = round_questions[0 ..(20 - wrong_questions.length - 1)]
        questions = wrong_questions + rs_question
        rs_question.map{|q| q && q.round.round_scores.where(:round_scores => {:user_id => params[:uid]}).update_all(updated_at: Time.now) }
      end
    else
      questions = wrong_questions[0..19]
    end
    questions_arr = []
    questions.each{|question|
      q_hash = {}
      q_hash[:question_id] = question.id
      q_hash[:round_id] = question.round_id
      q_hash[:chapter_id] = question.round.chapter_id
      q_hash[:course_id] = question.round.course_id
      q_hash[:content] = question.content
      q_hash[:question_types] = question.types
      q_hash[:prefix] = "/mnt/sdcard/qixueguan/#{params[:uid]}/#{question.round.course_id}/#{question.round.chapter_id}/Round_#{question.round_id}/"
      q_hash[:branch_questions] = []
      question.branch_questions.each do |bq|
        bq_hash = {}
        bq_hash[:branch_question_id] = bq.id
        bq_hash[:branch_content] = bq.branch_content
        bq_hash[:branch_question_types] = bq.types
        bq_hash[:options] = bq.options
        bq_hash[:answer] = bq.answer
        q_hash[:branch_questions] << bq_hash
      end
      q_hash[:card_id] = question.knowledge_card.try(:id)
      q_hash[:card_name] = question.knowledge_card.try(:name)
      q_hash[:description] = question.knowledge_card.try(:description)
      questions_arr << q_hash
    }
    #每日任务默认血量是 5，  问题数量 20
    render :json =>{:questions => questions_arr, :status => status, :blood => BLOOD, :question_total => QUESTION_COUNT }
  end

  #每日任务做完后,1，更新登录天数, 更新金币
  def after_everyday_tasks
    #uid, course_id, gold
    EverydayTask.transaction do
      uid = params[:uid].to_i
      cid = params[:course_id].to_i
      et = EverydayTask.find_by_user_id_and_course_id(uid, cid)
      
      begin
        if et
          et.get_login_day  #更新每日任务登录天数
        else
          et = EverydayTask.create({:user_id => uid, :course_id => cid, :day => 1})
        end
        user_course_relarion = UserCourseRelation.find_by_user_id_and_course_id(uid, cid)
        user_course_relarion.update_attribute(:gold, user_course_relarion.gold.to_i + params[:gold].to_i) if user_course_relarion
        message = "success"
      rescue
        message = "error"
      end
      render :json => {:message => message, :login_day => et.day}
    end
  end

  #每日任务,做一题提交一次。增加新的错题或者删除错题库中答对的题目
  def remove_wrong_questions
    #uid, course_id, question_id, flag(0 错误 1 正确)
    response.header['Access-Control-Allow-Origin'] = '*'
    response.header['Content-Type'] = 'text'
    UserMistakeQuestion.transaction do
      umq = UserMistakeQuestion.find_by_user_id_and_question_id(params[:uid], params[:question_id])
      flag = params[:flag].to_i
      begin
        if flag == 0 && umq.blank?
          UserMistakeQuestion.create({:user_id => params[:uid], :question_id => params[:question_id], :course_id => params[:course_id], :wrong_time => Time.now()})
        elsif flag==1 && umq.present?
          umq.destroy
        end
        message = "success"
      rescue
        message = "error"
      end
      render :text => message
    end
  end

  def course_to_chapter  #课程到章节，根据关卡完成情况确定章节图片变化
    #参数uid， cid
    uid = params[:uid].to_i
    cid = params[:cid].to_i
    ucr = UserCourseRelation.find_by_user_id_and_course_id(uid, cid)
    course = Course.find_by_id(cid)
    if course
      et = EverydayTask.find_by_user_id_and_course_id(uid, cid)
      login_day = et && et.day || 0  #每日任务登录天数

      props = Prop.find_by_sql("select p.id prop_id, p.name prop_name, p.description, p.price, p.types, p.question_types,
  upr.user_prop_num, upr.user_id user_id from props p left join user_prop_relations upr on p.id=upr.prop_id  and ( upr.user_id=#{uid} || upr.user_id is null)
left join users u on u.id = upr.user_id and upr.user_prop_num >=1 where  p.course_id=#{cid} and p.status = #{PROP_STATUS_NAME[:normal]}") #道具列表(包含我的道具)
      props.map{|prop|
            if prop.user_prop_num.present? && prop.user_prop_num < 0
              props.delete(prop)
            else
              prop[:logo] = prop.img.thumb.url
            end 
        }
      #    props = props.select{|p| p.user_id == uid || p.user_id == nil}
      chapters = course.chapters.verified.select("id,name,rounds_count")

      chapter_num = chapters.count
      complete_arr = []
      chapters.each do |chapter|
        rs = RoundScore.where(:user_id => uid, :chapter_id => chapter.id) #章节所有关卡全部完成
        three_stars = RoundScore.where(:user_id => uid, :chapter_id => chapter.id, :star => ROUND_STAR[:three_star]) #章节所有关卡满星
        chapter[:all_complete] = (chapter.rounds_count == rs.count) ? 1 : 0
        chapter[:all_3_star] = (chapter.rounds_count == three_stars.count) ? 1 : 0
        complete_arr <<  chapter
      end
      render :json =>{:every_day_task => login_day, :props => props, :chapter_num => chapter_num, :chapters => complete_arr, :level => ucr.level, :gold => ucr.gold}
    else
      render :json => {:massage => "error"}
    end
  end

  #关联微博
  def bind_weibo
    #参数 uid, weibo_id, weibo_time,根据uid更新weibo_id和weibo_time
    user = User.find_by_id(params[:uid])
    if user && user.update_attributes({:weibo_id => params[:weibo_id], :weibo_time => params[:weibo_time]})
      message = "success"
    else
      message = "error"
    end
    render :json => {:message => message}
  end

  #添加通讯录、微博好友
  def add_friend
    #参数 uid, friend_id
    Friend.transaction do
      f1 = Friend.create({:user_id => params[:uid], :friend_id => params[:friend_id]})
      f2 = Friend.create({:user_id => params[:friend_id], :friend_id => params[:uid]})
      friend_count = Friend.find_all_by_user_id(params[:uid]).length
      render :json => { :message => f1&&f2 ? "success" : "error", :friend_count => friend_count}
    end
  end

  #返回通讯录好友
  def contact_list
    #参数 uid, phones逗号分隔
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
    weibo_ids = params[:weibo_ids].split(",").map(&:to_i)
    in_app_weibo_users = User.where(:weibo_id => weibo_ids)
    not_in_app_weibo_ids = weibo_ids - in_app_weibo_users.map(&:weibo_id)
    weibo_user_ids = in_app_weibo_users.map(&:id)
    friend_ids = Friend.where(:user_id => params[:uid]).map(&:friend_id)
    added_friend_ids = weibo_user_ids & friend_ids
    can_add_friend_ids = weibo_user_ids - friend_ids
    render :json =>{:added_weibo_friends => User.where(:id => added_friend_ids),
      :can_add_weibo_friends => User.where(:id => can_add_friend_ids), :not_opened_weibo_ids => not_in_app_weibo_ids}
  end

  #根据用户id跟课程id获取用户当前课程的等级、经验以及下次升级的经验
  def course_level
    #course_id,round_id,chapter_id, uid,experience_vaule（关卡得分/经验值），star, gold 保存经验值，关卡星级， 金币
    #新建记录 => round_scores, 更新记录 => user_course_relations   round_scores  增加标志（得分第一的标志）。score 跟 star 里面的值都是保存历史最高值
    course_id = params[:course_id].to_i
    chapter_id = params[:chapter_id].to_i
    uid = params[:uid].to_i
    round_id = params[:round_id].to_i
    gold = params[:gold].to_i
    score = params[:experience_value].to_i
    star = params[:star].to_i
    UserCourseRelation.transaction do

      ucr = UserCourseRelation.find_by_course_id_and_user_id(course_id, uid)
      if ucr
        #保存关卡得分 开始
        round_score = RoundScore.find_by_user_id_and_round_id(uid, round_id) if uid

        if round_score
          round_score.update_attributes({:score => score, :star => star, :best_score => [score, round_score.best_score].max})
        else
          round_score = RoundScore.create(:user_id => uid, :chapter_id => chapter_id, :round_id => round_id,
            :score => score, :star => star, :best_score => score, :day => Time.now)
        end
        #保存关卡得分 结束

        if star == ROUND_STAR[:three_star] && !round_score.star_3flag #此关卡得过3星的标志
          round_score.update_attribute(:star_3flag, true)
        end

        #保存当前关卡，用户以及好友的得分排名 开始
        friend_ids = Friend.where(:user_id => uid).map(&:friend_id) << uid
        round_score_ranks = RoundScore.where({:round_id => round_id, :user_id => friend_ids}).order("best_score desc")

        round_score_ranks.each_with_index do |rs, index|
          if index == 0 && rs.user_id == uid && !round_score.toppest_flag
            round_score.update_attribute(:toppest_flag, true)  #此关卡有过排名第一的标志
          end

        end
        #保存当前关卡，用户以及好友的得分排名 结束
        course = Course.find_by_id(course_id)
        chapter_ids = course.chapter_ids if course
        star3_count = RoundScore.where(:chapter_id => chapter_ids || [], :star_3flag => true).length  #当前课程, 用户得3星的次数
        toppest_count = RoundScore.where(:chapter_id => chapter_ids || [], :toppest_flag => true).length  #当前课程, 用户得第一的次数


        old_exp_value = ucr.experience_value.to_i
        new_exp_value = old_exp_value + score
        level_exp_value = LevelValue.find_by_course_id_and_level(params[:course_id], ucr.level ).try(:experience_value).to_i
        if new_exp_value > level_exp_value
          new_level = (ucr.level || 1) + 1
          new_level_exp_value = LevelValue.find_by_course_id_and_level(params[:course_id], new_level ).try(:experience_value).to_i
          ucr.update_attributes({:experience_value => new_exp_value - level_exp_value, :level => new_level, :gold => ucr.gold.to_i + gold, :gold_total => ucr.gold_total.to_i + gold})
          render :json => {:status => 1, :old_exp_value => 0,:level => ucr.level, :new_exp_value =>  ucr.experience_value,
            :level_exp_value => new_level_exp_value, :gold => ucr.gold_total, :toppest_count => toppest_count, :star3_count => star3_count, :card_use_count => ucr.cardbag_use_count}
        else
          ucr.update_attributes({:experience_value => new_exp_value, :gold => ucr.gold.to_i + gold, :gold_total => ucr.gold_total.to_i + gold})
          render :json => {:status => 0, :old_exp_value => old_exp_value,:level => ucr.level, :new_exp_value =>  ucr.experience_value,
            :level_exp_value => level_exp_value, :gold => ucr.gold_total, :toppest_count => toppest_count, :star3_count => star3_count, :card_use_count => ucr.cardbag_use_count}
        end
      else
        render :json => {:message => "record_not_found"}
      end
    end
    #返回值加上累计金币，当前课程当前用户关卡排名第一的次数

    #计算成就
    #知识卡片使用数量
    #三星数目
    #第一数目


  end

end