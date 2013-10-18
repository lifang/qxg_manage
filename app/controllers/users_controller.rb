#encoding: utf-8
class UsersController < ApplicationController
  before_filter :sign?

  def index
    @users = User.signed_user
  end

  def show
    @user = User.find_by_id params[:id]
    
  end
end