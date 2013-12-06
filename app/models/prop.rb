#encoding: utf-8
class Prop < ActiveRecord::Base
  belongs_to :course
  has_many :user_prop_relations
  has_many :props, :through => :user_prop_relations
  
  mount_uploader :img, AvatarUploader

  STATUS = {0 => "正常", 1 => "删除"}
  STATUS_NAME = {:normal => 0, :delete => 1}
  TYPES = {0 => "答题前", 1 => "答题中", 2 => "答题后"}

  scope :status_method, ->(status) {where(:status => status) }

  validate :unique_name

  def unique_name
    prop = Prop.where("course_id = ? and status != ? and name = ?", course_id, STATUS_NAME[:delete], name).first
    if (prop && prop.id != self.id)
      errors.add(:name, "同一课程下道具名称已存在！")
    end
  end

  def self.my_props(uid,cid)
    props = Prop.joins("inner join user_prop_relations u on props.id=u.prop_id").select("props.*,u.user_prop_num num").
      where("u.user_id=#{uid} and u.user_prop_num >=1 and course_id=#{cid}")
    props
  end
end
