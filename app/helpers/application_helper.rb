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

  #根据课程下面的关卡数目，设定每一级需要的经验值
  def update_course_level(rounds_count)
    level = round_level(rounds_count)
    exp_arr = level_arr(level).map(&:to_i)
    exp_arr
  end

  #设定关卡数目对应的等级数目
  def round_level(rounds_count)
    if rounds_count < 100
      level = 5
    elsif rounds_count >= 100 && rounds_count < 200
      level = 10
    elsif rounds_count >= 200 && rounds_count < 300
      level = 20
    elsif rounds_count >= 300 && rounds_count < 400
      level = 30
    else
      level = 40
    end
    level
  end

  # 根据课程下面的关卡数目，设定每一级需要的经验值
  def level_arr(level)
    exp = Array.new(level)
    num = 1
    sum = 1
    m = 1
    exp[0] = 1
    i = 1
    while(i < level)
      num = (num + i) * (1 + (i / 200.to_f))
      sum += num
      exp[i] = num
      i = i + 1
    end
p sum
    m = 100/sum.to_f
    f = 0
    while(f < exp.length)
      exp[f] = exp[f] * m
      exp[f] = exp[f]*150+500
      f = f + 1
    end
    exp
  end
end
