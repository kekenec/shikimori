class TopicViewing < ActiveRecord::Base
  belongs_to :user
  belongs_to :viewed, class_name: Topic.name, foreign_key: :viewed_id
end
