#encoding: utf-8
class Api::UsersController < ActionController::Base
  def login     #登陆
    email = params[:email]
    user = User.find_by_email(email)
    password = params[:password]
    if user
      if Digest::SHA2.hexdigest(password) != user.password
        render :json => "error_pwd"
      else
        courses = Course.find_by_sql("select ucr.*, c.* from users u left join user_course_relations ucr on u.id=user_id
                                      left join courses c on ucr.course_id=c.id
                                      where u.id=#{user.id}")
        props = Prop.find_by_sql("select upr.*,p.* from users u left join user_prop_relations upr on u.id=upr.user_id
                                  left join props p on upr.prop_id=p.id
                                  where u.id=#{user.id}")
        render :json => {:user => user, :courses => courses, :props => props}
      end
    else
      render :json => "error_email"
    end
  end

  def regist    #注册
    email = params[:email]
    name = params[:name]
    pwd = params[:password]
    phone = params[:phone]
    user = User.new(:email => email, :name => name, :phone => phone, :types => User::TYPES[:NORMAL])
    user.encrypt_password(pwd)
    if user.save
      render :json => "success"
    else
      render :json => user.errors.messages.values.flatten.join(",")
    end
  end


  def update_user_date    #编辑更新
    user = User.find_by_id(params[:uid].to_i)
    name = params[:name].strip
    birthday = params[:birthday]
    sex = params[:sex]
    phone = params[:phone]
    if name.nil? || name.empty?
      render :json => "name is empty"
    else
      if user.update_attributes(:name => name, :birthday => birthday, :sex => sex, :phone => phone)
        render :json => "success"
      else
        render :json => "error"
      end
    end
  end

  def upload_head_img     #上传头像
    img = params[:img]
    uid = params[:uid]
    user = User.find_by_id(uid)
    url = User.upload_img(img, uid, "user_head_img")
    if user.update_attribute("img", url)
      render :json => {:message => "success", :img => user.img}
    else
      render :json => "error"
    end
  end

  def set_password      #设置密码
    opwd = params[:old_password]
    npwd = params[:new_password]
    user = User.find_by_id(params[:uid].to_i)
    if Digest::SHA2.hexdigest(opwd) != user.password
      render :json => "error_password"
    else
      if user.update_attribute(:password, Digest::SHA2.hexdigest(npwd))
        render :json => "success"
      else
        render :json => "error"
      end
    end
  end

  def set_email #修改邮箱
    uid = params[:uid].to_i
    pwd = params[:pwd]
    email = params[:email].strip
    user = User.find_by_id(uid)
    if user.nil?
      render :json => "error"
    else
      if Digest::SHA2.hexdigest(pwd) != user.password
        render :json => "error_password"
      else
        if User.find_by_email(email).present?
          render :json => "error_email"
        else
          user.update_attribute("email", email)
          render :json => "success"
        end
      end
    end
  end
  
end