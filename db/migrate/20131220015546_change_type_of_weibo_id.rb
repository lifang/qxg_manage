class ChangeTypeOfWeiboId < ActiveRecord::Migration
  def change
    change_column :users, :weibo_id, :bigint
  end
end
