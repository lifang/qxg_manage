module ApplicationHelper
  include QuestionHelper
  include CoursesHelper
  def sign?
    deny_access unless signed_in?
  end

  def deny_access
    redirect_to "/"
  end

  def signed_in?
    return session[:email] != nil
  end

  # Format text for display.
  def format(text)
    sanitize(markdown(text))
  end

  # Process text with Markdown.
  def markdown(text)
    BlueCloth::new(text).to_html
  end

end
