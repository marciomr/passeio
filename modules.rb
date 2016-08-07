require './connect_db.rb'

class Page < ActiveRecord::Base
  has_many :pages, through: :likes
end

class Like < ActiveRecord::Base
  belongs_to :from, class_name: "Page"
  belongs_to :to, class_name: "Page"
end
