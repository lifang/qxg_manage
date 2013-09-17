#encoding: utf-8
class User < ActiveRecord::Base
  validates :email, :uniqueness => {:message => "该邮箱已注册会员", :scope => :types}, :if => :user_not_deleted?
  TYPES = {           #用户类型
    :ADMIN => 0,
    :NORMAL => 1,
    :DELETED => 2
  }

  
  def user_not_deleted?
    types != TYPES[:DELETED]
  end

  def encrypt_password(pwd)
    self.password = Digest::SHA2.hexdigest(pwd)
  end

end
