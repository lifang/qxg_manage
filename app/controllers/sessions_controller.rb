#encoding: utf-8
class SessionsController < ApplicationController
  def new
    render :layout => nil
  end

  def create
    @email = params[:user_email]
    password = params[:user_password]
    user = User.find_by_email(@email)
    if user && user.password == Digest::SHA2.hexdigest(password) && user.types==0
      session[:email] = user.email
      redirect_to courses_path
    else
      flash.now[:notice]="用户名或密码错误"
      render :new
    end
  end

  def destroy
    session[:email] = nil
    redirect_to "/"
  end
end