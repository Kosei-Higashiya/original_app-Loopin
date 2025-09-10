class Tag < ApplicationRecord
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :name, format: { with: /\A[a-zA-Z0-9_\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]+\z/, message: "は文字、数字、アンダースコアのみ使用できます" }

  before_save :normalize_name

  scope :popular, -> { joins(:posts).group('tags.id').order('COUNT(posts.id) DESC') }

  # Ransack設定
  def self.ransackable_attributes(auth_object = nil)
    ["name", "created_at", "id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["posts"]
  end

  private

  # 空白を削除し、小文字に変換
  def normalize_name
    self.name = name.strip.downcase if name
  end
end
