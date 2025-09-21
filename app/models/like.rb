class Like < ApplicationRecord
  belongs_to :user
  belongs_to :post

  # 一つのユーザーは同じ投稿に対して一度だけいいねできる
  validates :user_id, uniqueness: { scope: :post_id }
end
