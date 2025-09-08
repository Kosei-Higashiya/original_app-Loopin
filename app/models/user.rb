class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :habits, dependent: :destroy
  has_many :habit_records, dependent: :destroy
  has_many :posts, dependent: :destroy

  # 名前が空の場合、ゲストを表示名として返す
  def display_name
    name.present? ? name : "ゲスト"
  end
end
