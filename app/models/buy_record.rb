#encoding: utf-8
class BuyRecord < ActiveRecord::Base
  include Constant
  belongs_to :prop
end