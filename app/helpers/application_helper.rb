module ApplicationHelper
  def sign?
    deny_access unless signed_in?
  end

  def deny_access
    redirect_to "/"
  end

  def signed_in?
    return session[:email] != nil
  end

end
