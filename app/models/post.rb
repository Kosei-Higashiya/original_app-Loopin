class Post < ApplicationRecord
  belongs_to :user
  belongs_to :habit
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  validates :content, presence: true, length: { maximum: 1000 }
  validates :image, length: { maximum: 255 }

  scope :recent, -> { order(created_at: :desc) }
  scope :with_associations, -> { includes(:user, :habit, :tags) }
  scope :tagged_with, ->(tag_name) { joins(:tags).where(tags: { name: tag_name }) }
  
  def tag_list
    tags.pluck(:name).join(', ')
  end
  
  def tag_list=(names)
    tag_names = names.split(',').map(&:strip).reject(&:blank?)
    self.tags = tag_names.map do |name|
      Tag.find_or_create_by(name: name.downcase)
    end
  end
end
