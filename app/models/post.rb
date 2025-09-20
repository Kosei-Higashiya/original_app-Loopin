class Post < ApplicationRecord
  belongs_to :user
  belongs_to :habit
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many :likes, dependent: :destroy
  has_many :liked_by_users, through: :likes, source: :user

  validates :content, presence: true, length: { maximum: 1000 }

  scope :recent, -> { order(created_at: :desc) }
  scope :with_associations, -> { includes(:user, :habit, :tags) }
  scope :tagged_with, ->(tag_name) { joins(:tags).where(tags: { name: tag_name }) }

  # Ransack設定
  def self.ransackable_attributes(_auth_object = nil)
    %w[content created_at id updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[habit tags user]
  end

  # 投稿に紐づいているタグをカンマ区切りの文字列で返す。
  def tag_list
    tags.pluck(:name).join(', ')
  end

  # カンマ区切り, 空白削除, 重複削除したタグ名の配列を受け取り、タグを関連付ける。
  def tag_list=(names)
    tag_names = names.split(',').map(&:strip).reject(&:blank?).uniq
    self.tags = tag_names.map do |name|
      Tag.find_or_create_by(name: name)
    end
  end

  # Check if the post is liked by a specific user
  def liked_by?(user)
    return false unless user

    likes.exists?(user: user)
  end
end
