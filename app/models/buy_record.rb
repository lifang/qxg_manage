class BuyRecord < ActiveRecord::Base
  
  TYPES = {0 => "购买", 1 => "使用"}
  TYPE_NAME = {:buy => 0, :use => 1}
  
end