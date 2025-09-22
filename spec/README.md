# RSpec テスト設定

このプロジェクトには RSpec を使用したモデルテストとシステムテストが含まれています。

## セットアップ済み内容

### Gemfile に追加された gem
- `rspec-rails` - RSpec for Rails
- `factory_bot_rails` - テストデータファクトリー
- `database_cleaner-active_record` - テスト実行間のデータベースクリーンアップ
- `sqlite3` - テスト用データベース

### RSpec 設定
- `.rspec` - RSpec 設定ファイル
- `spec/rails_helper.rb` - Rails 用設定
- `spec/spec_helper.rb` - 基本設定

### テストファイル構成

#### ファクトリー (`spec/factories/`)
- `users.rb` - ユーザーファクトリー
- `habits.rb` - 習慣ファクトリー
- `habit_records.rb` - 習慣記録ファクトリー
- `posts.rb` - 投稿ファクトリー
- `badges.rb` - バッジファクトリー
- `likes.rb` - いいねファクトリー
- `tags.rb` - タグファクトリー

#### モデルテスト (`spec/models/`)
- `user_spec.rb` - ユーザーモデル
- `habit_spec.rb` - 習慣モデル
- `habit_record_spec.rb` - 習慣記録モデル
- `post_spec.rb` - 投稿モデル
- `badge_spec.rb` - バッジモデル

#### システムテスト (`spec/system/`)
- `authentication_spec.rb` - ユーザー認証
- `habits_spec.rb` - 習慣管理
- `posts_spec.rb` - SNS機能（投稿・いいね）
- `badges_spec.rb` - バッジシステム

## テストの実行方法

### モデルテスト
```bash
bundle exec rspec spec/models/
```

### 特定のテストファイル
```bash
bundle exec rspec spec/models/user_spec.rb
```

### システムテスト（ブラウザ環境が必要）
```bash
bundle exec rspec spec/system/
```

### 全テスト
```bash
bundle exec rspec
```

## 注意事項

- システムテストは Chrome ブラウザが必要です
- テスト環境では SQLite を使用しています（本番・開発は PostgreSQL）
- 一部のテストでは日本語のエラーメッセージを期待していますが、i18n設定により実際のメッセージとは異なる場合があります

## 今後の改善点

- システムテストのブラウザドライバー設定の最適化
- 日本語エラーメッセージの統一
- CI/CD パイプラインでのテスト実行設定