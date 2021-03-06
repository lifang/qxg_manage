#encoding: utf-8
class Api::ChaptersController < ApplicationController
  include Constant
  #我的道具
  def user_prop
    #uid, course_id
    response.header['Access-Control-Allow-Origin'] = '*'
    response.header['Content-Type'] = 'application/json'
    render :json => Prop.my_props(params[:uid],params[:course_id])
  end

  #章节下所有关卡列表
  #张，是否是自己跟好友，还是此关卡所有人？
  def user_round
    #uid, chapter_id
    uid = params[:uid].to_i
    chapter_id = params[:chapter_id].to_i
    chapter = Chapter.find_by_id chapter_id
    if chapter
      friend_ids = Friend.where(:user_id => uid).map(&:friend_id) << uid
      friend_ids = friend_ids.uniq
      rounds = Round.find_by_sql(["SELECT distinct r.id, r.chapter_id, r.name, r.questions_count, r.round_time, r.time_ratio, r.blood,
 r.max_score, rs.score score, rs.star from rounds r LEFT JOIN round_scores rs on r.id=rs.round_id AND rs.user_id = ? where
r.chapter_id = #{chapter_id} and r.course_id = #{chapter.course_id} and r.status=#{VARIFY_STATUS[:verified]} order by r.id asc", uid])

      round_range = RoundScore.find_by_sql(["select u.name u_name, u.id uid, u.img img, rs.best_score score, rs.round_id round_id from round_scores rs inner join rounds r on r.id = rs.round_id
      inner join users u on rs.user_id = u.id where rs.round_id in (?) and rs.user_id in (?) order by rs.best_score desc", rounds.map(&:id), friend_ids]).group_by{|rs| rs.round_id}
      rs_hash = {}

      round_range.each do |round_id, users|
        temp_users = users[0..2]
        if temp_users.map(&:uid).include?(uid)
          rs_hash[round_id] = temp_users
        else
          rs_hash[round_id] = temp_users
          users.each_with_index do |u,index|
            if u.uid == uid
              u[:rank] = index+ 1
              rs_hash[round_id] << u
            end
          end
        end
      end

      #加上每个关卡里面的知识卡片信息
      knowledge_cards = KnowledgeCard.find_by_sql(["select kc.id, kc.name, kc.description, q.round_id from knowledge_cards kc inner join questions q
on q.knowledge_card_id = kc.id and q.round_id in (?)", rounds.map(&:id)]).group_by{|rs| rs.round_id}
      has_score_rounds = rs_hash.keys
      render :json => {:rounds => rounds, :round_range => rs_hash, :round_ids => has_score_rounds, :knowledge_cards => knowledge_cards}
    else
      render :json => {:message => "no chapter"}
    end

  end

  #使用道具
  def used_prop
    #prop_id, uid
    response.header['Access-Control-Allow-Origin'] = '*'
    response.header['Content-Type'] = 'text'
    Prop.transaction do
      prop = Prop.find_by_id(params[:prop_id])
      prop_use_record = BuyRecord.create({:user_id => params[:uid], :prop_id => params[:prop_id], :count => 1, :gold => prop.price, :types => PROP_TYPE_NAME[:use]}) if prop
      user_prop = UserPropRelation.where(:user_id => params[:uid],:prop_id => params[:prop_id]).first
      up = user_prop.update_attributes(:user_prop_num => user_prop.user_prop_num-1) if user_prop
      render :text => prop_use_record&&up ? "success" : "error"
    end
  end

  #使用道具
  def rouns_used_prop
    #prop_ids(逗号分隔), uid, course_id
    Prop.transaction do
      flag = true
      prop_ids = params[:prop_ids].split(",")
      prop_ids.each do |prop_id|
        prop = Prop.find_by_id(prop_id)
        prop_use_record = BuyRecord.create({:user_id => params[:uid], :prop_id => prop_id, :count => 1, :gold => prop.price, :types => PROP_TYPE_NAME[:use]}) if prop
        user_prop = UserPropRelation.where(:user_id => params[:uid],:prop_id => prop_id).first
        up = user_prop.update_attributes(:user_prop_num => user_prop.user_prop_num-1) if user_prop
        flag = prop_use_record&&up
      end
      render :json => {:message => flag ? "success" : "error", :props => flag ? Prop.my_props(params[:uid],params[:course_id]) : []}
    end
  end

  #收藏知识卡片
  def save_card
    #uid， card_id, course_id
    response.header['Access-Control-Allow-Origin'] = '*'
    response.header['Content-Type'] = 'text'
    user_course_relation = UserCourseRelation.find_by_user_id_and_course_id(params[:uid], params[:course_id])
    if user_course_relation && ((user_course_relation.cardbag_count.to_i - user_course_relation.cardbag_use_count.to_i) > 0)
      user_card_relation = UserCardsRelation.find_by_user_id_and_knowledge_card_id(params[:uid], params[:card_id] )
      user_card_relation_new = UserCardsRelation.create(:user_id=>params[:uid],:knowledge_card_id => params[:card_id], :course_id => params[:course_id]) unless user_card_relation
      ucr = user_course_relation.update_attribute(:cardbag_use_count, user_course_relation.cardbag_use_count + 1) unless user_card_relation
      render :text => user_card_relation ? "added" : (user_card_relation_new && ucr ? "success" : "error")
    else
      render :text => "not_enough"
    end
  end

  #返回收藏的知识卡片（卡包）
  def user_cards
    #course_id, uid
    ucr = UserCourseRelation.find_by_user_id_and_course_id(params[:uid], params[:course_id])
    knowledge_cards = KnowledgeCard.joins(:user_cards_relations).select("knowledge_cards.*, user_cards_relations.remark remark").where(:user_cards_relations => {:user_id=>params[:uid],:course_id => params[:course_id]})

    tags = CardbagTag.find_by_sql("select id,name,user_id,course_id,types from cardbag_tags where (course_id = #{params[:course_id]} and user_id is null) or (course_id = #{params[:course_id]} and user_id =#{params[:uid]})")

    tag_cards = CardTagRelation.joins(:cardbag_tag).where(:course_id => params[:course_id],
      :knowledge_card_id => knowledge_cards.map(&:id)).select("cardbag_tags.id, cardbag_tags.name, cardbag_tags.types, knowledge_card_id")

    tag_card_hash = tag_cards.group_by { |re| re.knowledge_card_id }

    knowledge_cards.each{|card| card[:tag_ids] = (tag_card_hash[card.id] && tag_card_hash[card.id].map(&:id)) || []}
    render :json =>{:cards => knowledge_cards, :tags => tags, :cards_total => ucr.try(:cardbag_count), :cards_left_count => ucr.try(:cardbag_count).to_i - ucr.try(:cardbag_use_count).to_i}
  end


  #移除知识卡片
  def delete_card
    #uid ,card_id, course_id
    user_cards_relation = UserCardsRelation.where(:user_id=>params[:uid],:knowledge_card_id => params[:card_id]).first
    user_cards_relation.destroy
    user_course_relation = UserCourseRelation.find_by_user_id_and_course_id(params[:uid], params[:course_id])
    ucr = user_course_relation.update_attribute(:cardbag_use_count, user_course_relation.cardbag_use_count - 1) if user_course_relation
    render :json => {:message =>  ucr ? "success" : "error"}
  end

  #保存成就点数,user_course_relations 累加成就点数，Achieve新增记录
  def save_achieve
    #参数 uid, course_id， achieve_point (achieve_id)_point 成就可能多个
    #更新
    uid = params[:uid]
    course_id = params[:course_id]
    Achieve.transaction do
      user_course_relarion = UserCourseRelation.find_by_user_id_and_course_id(uid, course_id)
      begin
        if user_course_relarion && params[:achieve_point]
          params[:achieve_point].split(",").each do |ap|
            achieve_data_id = ap.split("_")[0].to_i
            point = ap.split("_")[1].to_i
            achieve = Achieve.find_by_user_id_and_course_id_and_achieve_data_id(uid, course_id, achieve_data_id)
            Achieve.create({:user_id => uid, :course_id => course_id, :achieve_data_id => achieve_data_id, :point => point}) unless achieve

            user_course_relarion.update_attribute(:achieve_point, user_course_relarion.achieve_point + point)
          end
        end
        message = "success"
      rescue
        message = "error"
      end
      render :json => {:message => message}
    end
  end

  #知识卡片添加标签
  def add_tag_to_card
    #参数uid, card_id, tag_id, course_id
    CardTagRelation.transaction do
      ctr = CardTagRelation.where({:user_id => params[:uid], :knowledge_card_id => params[:card_id], :course_id => params[:course_id], :cardbag_tag_id => params[:tag_id]})
      if ctr.present?
        render :json => {:message => "added"} #卡片已经加在当前标签下
      else
        card_tag_relation = CardTagRelation.create({:user_id => params[:uid], :knowledge_card_id => params[:card_id], :course_id => params[:course_id], :cardbag_tag_id => params[:tag_id]})
        render :json => {:message => card_tag_relation ? "success" : "error"}
      end
    end
  end

  #知识卡片添加备注
  def add_remark_to_card
    #参数 uid， course_id, card_id, remark
    user_card_relation = UserCardsRelation.where(:course_id  => params[:course_id], :user_id => params[:uid],
      :knowledge_card_id => params[:card_id])[0]
    render :json => {:message => user_card_relation && user_card_relation.update_attribute(:remark, params[:remark].strip) ? "success" : "error"}
  end

  #用户自定义添加标签
  def user_add_tag
    #参数uid, tag_name, course_id
    CardbagTag.transaction do
      cardbag_tag = CardbagTag.create({:name => params[:tag_name],:user_id => params[:uid], :course_id => params[:course_id], :types => TAG_TYPE_NAME[:user]})
      render :json => {:message => cardbag_tag ? "success" : "error", :tag => cardbag_tag}
    end
  end

  #用户自定义修改标签
  def user_update_tag
    #参数tag_id, tag_name
    CardbagTag.transaction do
      cardbag_tag = CardbagTag.find_by_id(params[:tag_id])
      ct = cardbag_tag.update_attribute(:name, params[:tag_name])
      render :json => {:message => ct ? "success" : "error"}
    end
  end

  #用户自定义删除标签
  def user_del_tag
    #参数tag_id
    cardbag_tag = CardbagTag.find_by_id(params[:tag_id])
    ct = cardbag_tag.destroy
    render :json => {:message => ct ? "success" : "error"}
  end

  #购买卡槽
  def buy_card_slot
    #参数uid，course_id, num, gold
    bcr = BuyCardbagRecord.create({:user_id => params[:uid], :course_id => params[:course_id], :num => params[:num], :gold => params[:gold]})
    user_course_relation = UserCourseRelation.find_by_user_id_and_course_id(params[:uid], params[:course_id])
    if user_course_relation
      ucr = user_course_relation.update_attributes(:cardbag_count => user_course_relation.cardbag_count + params[:num].to_i, :gold => user_course_relation.gold.to_i - params[:gold].to_i)
      cardbag_use_count = user_course_relation.cardbag_count.to_i - user_course_relation.cardbag_use_count.to_i
    end
    render :json => {:message => bcr&&ucr ? "success" : "error", :cardbag_left_count => cardbag_use_count.to_i}
  end

  #添加错题
  def add_wrong_question
    #uid, course_id, question_id,wrong_time
    response.header['Access-Control-Allow-Origin'] = '*'
    response.header['Content-Type'] = 'application/json'
    umq = UserMistakeQuestion.find_by_user_id_and_question_id(params[:uid], params[:question_id])
    umq_new = UserMistakeQuestion.create({:user_id => params[:uid], :course_id => params[:course_id], :question_id => params[:question_id], :wrong_time => Time.now}) unless umq
    render :text => umq ? "added" : (umq_new ? "success" : "error")
  end

  #用户前台删除课程
  def user_delete_course
    #uid, course_id
    begin
      uid, course_id = params[:uid], params[:course_id]
      UserCourseRelation.transaction do
        ucr = UserCourseRelation.find_by_user_id_and_course_id(uid, course_id).destroy #删除用户课程关系记录
        user_mistake_questions = UserMistakeQuestion.where(:user_id => uid, :course_id => course_id).delete_all #删除用户课程错题记录
        achieves = Achieve.where(:user_id => uid, :course_id => course_id).delete_all #删除用户获得成就记录
        buy_cardbag_records = BuyCardbagRecord.where(:user_id => uid, :course_id => course_id).delete_all #删除用户购买卡包记录
        buy_records = BuyRecord.where(:user_id => uid, :course_id => course_id).delete_all #删除用户购买/使用道具记录
        card_tag_relations = CardTagRelation.where(:user_id => uid, :course_id => course_id).delete_all #删除卡片添加标签记录
        cardbag_tags = CardbagTag.where(:user_id => uid, :course_id => course_id).delete_all #删除自定义标签记录
        everyday_tasks = EverydayTask.where(:user_id => uid, :course_id => course_id).delete_all #删除每日任务记录
        round_scores = RoundScore.joins("chapter").where(:chapters => {:course_id => course_id}, :user_id => uid).delete_all
        user_cards_relations = UserCardsRelation.where(:user_id => uid, :course_id => course_id).delete_all #删除用户收藏知识卡片记录
        user_prop_relations = UserPropRelation.joins("prop").where(:user_id => uid, :props => {:course_id => course_id}).delete_all #删除用户道具记录
      end
      message = "success"
    rescue
      message = "error"
    end
    render :json => {:message => message}
  end

  #下载课程时请求保存user_course_relations
  def save_user_course
    #uid,course_id，卡包默认值25
    uid,course_id = params[:uid],params[:course_id]
    UserCourseRelation.transaction do
      ucr = UserCourseRelation.find_by_course_id_and_user_id(course_id, uid)
      ucr_new = UserCourseRelation.create({:user_id => uid, :course_id => course_id, :cardbag_count => CARD_BAG_DEFAULT, :cardbag_use_count => 0, :gold => 0,
          :gold_total => 0, :level => 1, :achieve_point => 0, :experience_value => 0 }) unless ucr
      render :json => {:message => ucr_new ? "success" : "error"}
    end
  end

end
