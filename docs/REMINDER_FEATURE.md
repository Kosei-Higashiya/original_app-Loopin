# リマインダー機能

## 概要

週次リマインダー機能は、今週まだ習慣の記録をつけていないユーザーに対して、週1回自動的にリマインドメールを送信します。

メールは**Gmail経由**で、ユーザーが登録時に使用したメールアドレスに送信されます。

## 機能の詳細

### 対象ユーザー

以下の条件を満たすユーザーにリマインダーメールが送信されます：

- 今週（月曜日から現在まで）に `habit_records` を作成していない
- 今週（月曜日から現在まで）に `posts` を作成していない

### スケジュール

- **頻度**: 週1回
- **曜日**: 毎週月曜日
- **時刻**: 午前9時

### メール内容

- **送信元**: noreply@loopin-app.com（ApplicationMailerで設定）
- **送信先**: ユーザーの登録メールアドレス
- **配信方法**: Gmail SMTP経由
- **件名**: 【Loopin】今週の記録をつけましょう！
- **本文**: 
  - ユーザーの名前（またはゲスト）
  - 今週まだ記録をつけていないことの通知
  - Loopinへのアクセスリンク
  - 自動送信メールである旨の注記

## 技術的な実装

### 使用技術

- **whenever gem**: cronジョブの管理
- **Action Mailer**: メール送信
- **Active Job**: 非同期メール配信
- **Gmail SMTP**: メール配信サービス（本番環境）

### ファイル構成

```
app/
  mailers/
    reminder_mailer.rb                    # リマインダーメーラー
  views/
    reminder_mailer/
      weekly_reminder.html.erb            # HTMLメールテンプレート
      weekly_reminder.text.erb            # テキストメールテンプレート

config/
  schedule.rb                             # cron設定ファイル

lib/
  tasks/
    reminders.rake                        # リマインダー送信タスク

spec/
  mailers/
    reminder_mailer_spec.rb               # メーラーのテスト
  tasks/
    reminders_spec.rb                     # rakeタスクのテスト
```

## セットアップ

### 1. Gemのインストール

```bash
bundle install
```

### 2. Gmail SMTP設定（本番環境）

リマインダーメールは、ユーザー登録時に使用されたメールアドレスにGmail経由で送信されます。

本番環境で以下の環境変数を設定してください：

```bash
SMTP_ADDRESS=smtp.gmail.com          # デフォルト値
SMTP_PORT=587                         # デフォルト値
SMTP_DOMAIN=app-loopin.com           # デフォルト値
SMTP_USERNAME=your-gmail@gmail.com   # 必須：Gmail アカウント
SMTP_PASSWORD=your-app-password      # 必須：Gmail アプリパスワード
SMTP_AUTHENTICATION=plain             # デフォルト値
SMTP_ENABLE_STARTTLS_AUTO=true       # デフォルト値
```

**Gmail アプリパスワードの取得方法：**

1. Googleアカウントの「セキュリティ」設定にアクセス
2. 「2段階認証プロセス」を有効化（まだの場合）
3. 「アプリパスワード」を生成
4. 生成されたパスワードを `SMTP_PASSWORD` に設定

**重要**: 通常のGmailパスワードではなく、アプリパスワードを使用してください。

### 3. Cronジョブの更新

本番環境でcronジョブを設定するには、以下のコマンドを実行します：

```bash
bundle exec whenever --update-crontab
```

### 4. Cronジョブの確認

設定されたcronジョブを確認するには：

```bash
bundle exec whenever
```

または

```bash
crontab -l
```

### 5. Cronジョブの削除

cronジョブを削除するには：

```bash
bundle exec whenever --clear-crontab
```

## 手動実行

開発環境やテスト目的で手動でリマインダーを送信する場合：

```bash
bundle exec rake reminders:send_weekly
```

## ログ

wheneverによって実行されるcronジョブのログは以下の場所に保存されます：

- 標準出力: `log/whenever.log`
- エラー出力: `log/whenever_error.log`

## テスト

### メーラーのテスト

```bash
bundle exec rspec spec/mailers/reminder_mailer_spec.rb
```

### Rakeタスクのテスト

```bash
bundle exec rspec spec/tasks/reminders_spec.rb
```

### 全てのテストを実行

```bash
bundle exec rspec
```

## メールプレビュー

開発環境でメールのプレビューを確認するには、Rails サーバーを起動して以下にアクセスします：

```
http://localhost:3000/rails/mailers/reminder_mailer/weekly_reminder
```

## 環境設定

### 本番環境

`config/schedule.rb` はデフォルトで本番環境(`production`)を使用します。

### 開発・ステージング環境

異なる環境で実行する場合は、`RAILS_ENV`環境変数を設定してください：

```bash
RAILS_ENV=staging bundle exec whenever --update-crontab
```

## トラブルシューティング

### メールが送信されない

1. **Gmail SMTP認証情報を確認**
   ```bash
   # 環境変数が正しく設定されているか確認
   echo $SMTP_USERNAME
   echo $SMTP_PASSWORD  # 表示されることを確認（パスワードは表示されません）
   ```
   
   - Gmail アプリパスワードが正しく設定されているか
   - 2段階認証が有効になっているか
   - 通常のパスワードではなくアプリパスワードを使用しているか

2. **cronジョブが正しく設定されているか確認**
   ```bash
   crontab -l
   ```

3. **ログファイルを確認**
   ```bash
   tail -f log/whenever.log
   tail -f log/whenever_error.log
   tail -f log/production.log  # メール送信エラーの詳細
   ```

4. **メール設定を確認**
   - `config/environments/production.rb`のAction Mailer設定
   - SMTP設定が正しいか確認

### Gmail から「安全性の低いアプリ」エラーが出る場合

- 通常のGmailパスワードを使用している可能性があります
- **必ずアプリパスワード**を使用してください
- アプリパスワードの生成方法は上記のセットアップを参照

### 特定のユーザーにメールが送信されない

- そのユーザーが今週すでに活動している（habit_recordまたはpostを作成している）可能性があります
- 手動でタスクを実行して確認：
  ```bash
  bundle exec rake reminders:send_weekly
  ```

## カスタマイズ

### スケジュールの変更

`config/schedule.rb`を編集してスケジュールを変更できます：

```ruby
# 例: 毎週日曜日の午後7時に変更
every :sunday, at: '7:00 pm' do
  rake 'reminders:send_weekly'
end

# 例: 毎日午前10時に実行
every 1.day, at: '10:00 am' do
  rake 'reminders:send_weekly'
end
```

変更後、cronジョブを更新してください：

```bash
bundle exec whenever --update-crontab
```

### メールテンプレートのカスタマイズ

- HTML版: `app/views/reminder_mailer/weekly_reminder.html.erb`
- テキスト版: `app/views/reminder_mailer/weekly_reminder.text.erb`

これらのファイルを編集してメールの内容をカスタマイズできます。

## 今後の改善案

- [ ] ユーザーがリマインダーメールの受信設定をカスタマイズできる機能
- [ ] 異なる頻度のリマインダー（週次、月次など）
- [ ] リマインダーメールの開封率・クリック率の追跡
- [ ] A/Bテストによるメール文面の最適化
