class User < ApplicationRecord
  include BadgeChecker

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
  def max_consecutive_days
    unique_dates = habit_records.where(completed: true)
                                .pluck(:recorded_at)
                                .uniq
                                .sort

    return 0 if unique_dates.empty?

    max_streak = 1
    current_streak = 1

    unique_dates.each_cons(2) do |prev_date, curr_date|
      if (curr_date - prev_date).to_i == 1
        current_streak += 1
        max_streak = [max_streak, current_streak].max
      else
        current_streak = 1
      end
    end

    max_streak
  end

  # 全習慣の完了率を計算
  def overall_completion_rate
    return 0 if habits.empty?

    # 全習慣の全日付での総記録可能数を計算
    # ユーザーが過去30日間で記録できた総日数 × 習慣数
    thirty_days_ago = 30.days.ago.to_date
    today = Date.current
    total_possible_records = (today - thirty_days_ago + 1).to_i * habits.count

    # 実際に記録された習慣数（すべて completed: true）
    completed_records = habit_records.where(
      recorded_at: thirty_days_ago..today,
      completed: true
    ).count

    return 0 if total_possible_records.zero?

    (completed_records.to_f / total_possible_records * 100).round(1)
  end

  # 新しいバッジを自動的にチェックして付与

  def check_and_award_badges
    # バッジチェックモジュール(BadgeChecker)に処理を投げる
    results = check_and_award_badges_for_user(self)

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
