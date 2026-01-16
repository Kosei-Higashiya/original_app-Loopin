# cronジョブのスケジューリング設定ファイル
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# ログ出力先の設定
set :output, { error: 'log/whenever_error.log', standard: 'log/whenever.log' }

# 環境設定
set :environment, ENV.fetch('RAILS_ENV', 'production')

# 毎週月曜日の夜6時に、今週活動していないユーザーにリマインダーを送信
every :monday, at: '6:00 pm' do
  rake 'reminders:send_weekly'
end

# Learn more: http://github.com/javan/whenever
