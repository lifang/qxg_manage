#encoding: utf-8
class Api::ChaptersController < ApplicationController
  #章节列表
  def user_chapter
    chapters, rounds = Chapter.all,{}
    Round.joins("inner join round_scores r on rounds.id=r.round_id").select("max_score*0.9 <= r.score degree,rounds.chapter_id").
      where("r.user_id=#{params[:uid]} and max_score*0.9 <= r.score").each {|chapter| rounds[chapter.chapter_id]=chapter.degree}
    render :json=>{:chapters=>chapters,:chapter_status=>rounds}
  end

  #我的成就
  def user_achieve
    render :json => Achieve.where(:user_id=>params[:uid],:course_id=>params[:course_id]).select(:achieve_data_id).order("created_at desc").map(&:achieve_data_id).uniq
  end

  #我的道具
  def user_prop
    #uid, course_id
    #TODO
    response.header['Access-Control-Allow-Origin'] = '*'
    response.header['Content-Type'] = 'application/json'
    render :json => Prop.my_props(params[:uid],params[:course_id])
  end

  #关卡列表
  def user_round
    render :json => Round.joins("inner join round_scores r on rounds.id=r.round_id").where(:chapter_id =>params[:chapter_id],:"r.user_id"=>params[:uid]).
      select("name,r.star,rounds.id").inject(Hash.new){|hash,round| hash[round.id] = round;hash}
  end

  #关卡排名
  def user_rank
    rank_score,ranks,u_rank = {},{},{}
    RoundScore.joins("inner join users u on u.id=round_scores.user_id").where(:chapter_id =>params[:chapter_id]).select([:user_id,:score,:"u.name",:round_id]).
      each {|r| rank_score[r.round_id].nil? ?  rank_score[r.round_id]= {"#{r.score}_#{r.user_id}" => r} : rank_score[r.round_id].merge!({"#{r.score}_#{r.user_id}" => r});
      ranks[r.round_id]= {"#{r.score}_#{r.user_id}"=>r} if r.user_id == params[:uid].to_i}
    rank_score.each {|rank,v| u_rank[rank] = v.sort.reverse[0..2]}
    ranks.each {|k,v| ranks[k] = [rank_score[k].keys.sort.reverse.index(v.keys[0])+1,v.values[0]["score"]]}
    render :json => {:user_rank => u_rank,:my_rank => ranks}
  end

  #知识卡片列表
  def user_card
    render :json => KnowledgeCard.where(:course_id => params[:id]).select([:id,:name,:description])
  end

  #使用道具
  def used_prop
    prop = Prop.find_by_id(params[:prop_id])
    prop_use_record = BuyRecord.create({:user_id => params[:uid], :prop_id => params[:prop_id], :count => 1, :gold => prop.gold, :types => BuyRecord::TYPE_NAME[:use]}) if prop
    user_prop = UserPropRelation.where(:user_id => params[:uid],:prop_id => params[:prop_id]).first
    up = user_prop.update_attributes(:user_prop_num => user_prop.user_prop_num-1) if user_prop
    render :json=>{:msg => prop_use_record&&up ? "success" : "error"}
  end

  #收藏知识卡片
  def save_card
    #uid， card_id, course_id
    response.header['Access-Control-Allow-Origin'] = '*'
    response.header['Content-Type'] = 'text'
    user_course_relation = UserCourseRelation.find_by_user_id_and_course_id(params[:uid], params[:course_id])
    if user_course_relation && ((user_course_relation.cardbag_count.to_i - user_course_relation.cardbag_use_count.to_i) > 0)
      user_card_relation = UserCardsRelation.create(:user_id=>params[:uid],:knowledge_card_id => params[:card_id], :course_id => params[:course_id])
      ucr = user_course_relation.update_attribute(:cardbag_use_count, user_course_relation.cardbag_use_count + 1) if user_course_relation
      render :text => user_card_relation && ucr ? "success" : "error"
    else
      render :text => "not_enough"
    end
    
    
  end

  #返回收藏的知识卡片（卡包）
  def user_cards
    #course_id, uid
    knowledge_cards = KnowledgeCard.joins(:user_cards_relations).select("*")
    .where(:user_cards_relations => {:user_id=>params[:uid],:course_id => params[:course_id]})

    tags = CardbagTag.find_by_sql("select id,name,user_id,course_id,types from cardbag_tags where (course_id=1 and user_id is null) or (course_id=1 and user_id =2)")
    
    tag_cards = CardTagRelation.joins(:cardbag_tag).where(:course_id => params[:course_id],
      :knowledge_card_id => knowledge_cards.map(&:id))
    .select("cardbag_tags.id, cardbag_tags.name, cardbag_tags.types, knowledge_card_id")
     
    tag_card_hash = tag_cards.group_by { |re| re.knowledge_card_id }
     
    knowledge_cards.each{|card| card[:tag_ids] = (tag_card_hash[card.id] && tag_card_hash[card.id].map(&:id)) || []}
    render :json =>{:cards => knowledge_cards, :tags => tags}
  end


  #移除知识卡片
  def delete_card
    UserCardsRelation.where(:user_id=>params[:uid],:knowledge_card_id => params[:card_id]).first.destroy
    render :json=>{:msg => 1}
  end
  
  #卡片列表
  def list_card
    render :json =>KnowledgeCard.where(:course_id=>params[:course_id])
  end

  #保存关卡得分、成就、经验、等级信息
  def change_info

  end

  #知识卡片添加标签
  def add_tag_to_card
    #参数uid, card_id, tag_id, course_id
    ctr = CardTagRelation.where({:user_id => params[:uid], :knowledge_card_id => params[:card_id], :course_id => params[:course_id], :cardbag_tag_id => params[:tag_id]})
    if ctr.present?
      render :json => {:msg => "added"} #卡片已经加在当前标签下
    else
      card_tag_relation = CardTagRelation.create({:user_id => params[:uid], :knowledge_card_id => params[:card_id], :course_id => params[:course_id], :cardbag_tag_id => params[:tag_id]})
      render :json => {:msg => card_tag_relation ? "success" : "error"}
    end
    
  end

  #知识卡片添加备注
  def add_remark_to_card
    #参数 uid， course_id, card_id, remark
    user_card_relation = UserCardsRelation.where(:course_id  => params[:course_id], :user_id => params[:uid],
      :knowledge_card_id => params[:card_id])[0]
    render :json => {:msg => user_card_relation && user_card_relation.update_attribute(:remark, params[:remark].strip) ? "success" : "error"}
  end

  #用户自定义添加标签
  def user_add_tag
    #参数uid, tag_name, course_id
    cardbag_tag = CardbagTag.create({:name => params[:tag_name],:user_id => params[:uid], :course_id => params[:course_id], :types => CardbagTag::TYPE_NAME[:user]})
    render :json => {:msg => cardbag_tag ? "success" : "error", :tag_id => cardbag_tag.id}
  end

   #用户自定义修改标签
  def user_update_tag
    #参数tag_id, tag_name
    cardbag_tag = CardbagTag.find_by_id(params[:tag_id])
    ct = cardbag_tag.update_attribute(:name, params[:tag_name])
    render :json => {:msg => ct ? "success" : "error"}
  end

  #用户自定义删除标签
  def user_del_tag
    #参数tag_id
    cardbag_tag = CardbagTag.find_by_id(params[:tag_id])
    ct = cardbag_tag.destroy
    render :json => {:msg => ct ? "success" : "error"}
  end

  #购买卡槽
  def buy_card_slot
    #参数uid，course_id, num, gold
    bcr = BuyCardbagRecord.create({:user_id => params[:uid], :course_id => params[:course_id], :num => params[:num], :gold => params[:gold]})
    user_course_relation = UserCourseRelation.find_by_user_id_and_course_id(params[:uid], params[:course_id])
    ucr = user_course_relation.update_attribute(:cardbag_count, user_course_relation.cardbag_count + params[:num].to_i) if user_course_relation
    render :json => {:msg => bcr&&ucr ? "success" : "error"}
  end

  #添加错题
  def add_wrong_question
    #uid, course_id, question_id,wrong_time
    umq = UserMistakeQuestion.create({:user_id => params[:uid], :course_id => params[:course_id], :question_id => params[:question_id], :wrong_time => params[:wrong_time]})
    render :json => {:msg => umq ? "success" : "error"}
  end
end
