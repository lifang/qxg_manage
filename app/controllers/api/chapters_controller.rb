#encoding: utf-8
class Api::ChaptersController < ApplicationController

  #章节列表
  def user_chapter
    chapters, rounds = Chapter.all,{}
    Round.joins("inner join round_scores r on rounds.id=r.round_id").select("max_score*0.9 <= r.score degree,rounds.chapter_id").
      where("r.user_id=#{params[:id]} and max_score*0.9 <= r.score").each {|chapter| rounds[chapter.chapter_id]=chapter.degree}
    render :json=>{:chapters=>chapters,:chapter_status=>rounds}
  end

  #我的成就
  def user_achieve
    render :json => Achieve.where(:user_id=>params[:id],:course_id=>params[:course_id]).select(:achieve_data_id).order("created_at desc").map(&:achieve_data_id).uniq
  end

  #我的道具
  def user_prop
    render :json => Prop.joins("inner join user_prop_relations u on props.id=u.prop_id").select("props.*,u.user_prop_num num").
      where("u.user_id=#{params[:id]} and u.user_prop_num >=1 and course_id=#{params[:course_id]} ")
  end

  #关卡列表
  def user_round
    render :json => Round.joins("inner join round_scores r on rounds.id=r.round_id").where(:chapter_id =>params[:chapter_id],:"r.user_id"=>params[:id]).
      select("name,r.star,rounds.id").inject(Hash.new){|hash,round| hash[round.id] = round;hash}
  end

  #关卡排名
  def user_rank
    rank_score,ranks,u_rank = {},{},{}
    RoundScore.joins("inner join users u on u.id=round_scores.user_id").where(:chapter_id =>params[:chapter_id]).select([:user_id,:score,:"u.name",:round_id]).
      each {|r| rank_score[r.round_id].nil? ?  rank_score[r.round_id]= {"#{r.score}_#{r.user_id}" => r} : rank_score[r.round_id].merge!({"#{r.score}_#{r.user_id}" => r});
      ranks[r.round_id]= {"#{r.score}_#{r.user_id}"=>r} if r.user_id == params[:id].to_i}
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
    user_prop = UserPropRelation.where(:user_id => params[:id],:prop_id => params[:prop_id]).first
    user_prop.update_attributes(:user_prop_num => user_prop.user_prop_num-1)
    render :json=>{:msg => 1}
  end

  #收藏知识卡片
  def save_card
    UserCardsRelation.create(:user_id=>params[:id],:knowledge_card_id => params[:card_id])
    render :json=>{:msg => 1}
  end

  #查询收藏的知识卡片
  def search_card
    render :json => KnowledgeCard.joins(:user_cards_relations).select("*").where(:"user_cards_relations.user_id"=>params[:id])
  end


  #移除知识卡片
  def delete_card
    UserCardsRelation.where(:user_id=>params[:id],:knowledge_card_id => params[:card_id]).first.destroy
    render :json=>{:msg => 1}
  end
  
  #卡片列表
  def list_card
    render :json =>KnowledgeCard.where(:course_id=>params[:course_id])
  end


  def change_info
    
  end

  

end
