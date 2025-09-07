class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :habits, dependent: :destroy
  has_many :habit_records, dependent: :destroy
  has_many :posts, dependent: :destroy

  # Method to return name if present, otherwise email prefix
  def display_name
    name.present? ? name : email.split('@').first
  end
end
