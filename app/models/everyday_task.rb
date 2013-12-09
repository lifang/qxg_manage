#encoding: utf-8
class EverydayTask < ActiveRecord::Base
  BLOOD = 5
  QUESTION_COUNT = 20

  #返回每日任务连续登录天数
  def get_login_day
    task_time = self.updated_at.nil? || self.updated_at == "" ? 0 : self.updated_at.strftime("%Y%m%d").to_i
    now_time = Time.now.strftime("%Y%m%d").to_i
    if now_time - task_time > 1
      self.update_attribute("day", 0)
    end
    self.day
  end
end
