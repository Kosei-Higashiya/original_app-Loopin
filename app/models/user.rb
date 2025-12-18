class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :habits, dependent: :destroy
  has_many :habit_records, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :user_badges, dependent: :destroy
  has_many :badges, through: :user_badges
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post

  # OmniAuth callback handler
  def self.from_omniauth(auth)
    # まず provider と uid で検索
    user = where(provider: auth.provider, uid: auth.uid).first

    # 見つからなければ、同じメールアドレスのユーザーを探す
    if user.nil?
      user = find_by(email: auth.info.email)

      if user
        # User exists with email but different provider
        # Update provider and uid to link accounts
        user.update(provider: auth.provider, uid: auth.uid)
      else
        # Create new user
        user = create(
          provider: auth.provider,
          uid: auth.uid,
          email: auth.info.email,
          password: Devise.friendly_token[0, 20],
          name: auth.info.name
        )
      end
    end

    user
  end


  # 名前が空の場合、ゲストを表示名として返す
  def display_name
    name.presence || 'ゲスト'
  end

  # OAuthユーザーはパスワード不要
  def password_required?
    provider.blank? && super
  end

  # OAuthユーザーはパスワード確認不要
  def password_confirmation_required?
    provider.blank? && super
  end

  # バッジ関連メソッド
  def badge?(badge)
    user_badges.exists?(badge: badge)
  end

  # 獲得したバッジを取得
  def earned_badges
    badges.joins(:user_badges).order('user_badges.earned_at DESC')
  end

  # 統計メソッド（バッジ条件チェック用）
  # BadgeServiceに処理を委譲
  def max_consecutive_days
    BadgeService.send(:calculate_max_consecutive_days, self)
  end

  # 全習慣の完了率を計算
  # BadgeServiceに処理を委譲
  def overall_completion_rate
    BadgeService.send(:calculate_completion_rate, self)
  end

  # 新しいバッジを自動的にチェックして付与

  def check_and_award_badges
    # バッジチェックサービス(BadgeService)に処理を投げる
    results = BadgeService.check_and_award_badges_for_user(self)

    Rails.logger.debug do
      "Badge check completed for user #{id}. Awarded #{results[:newly_earned].count} badges via optimized checker"
    end

    # 新しく獲得したバッジの配列を返す
    results[:newly_earned] || []
  rescue StandardError => e
    Rails.logger.error "Error during optimized badge check for user #{id}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(3).join("\n")}" if e.backtrace
    # エラーが発生した場合は空の配列を返す
    []
  end
end
