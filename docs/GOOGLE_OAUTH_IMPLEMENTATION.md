# Google OAuth2 Login Implementation

このドキュメントは、Loopin アプリに追加された Google OAuth2 ログイン機能の実装詳細を説明します。

## 概要

既存の Devise 認証システムに OmniAuth を統合し、ユーザーが Google アカウントでログインできるようになりました。

## 実装された機能

### 1. Google OAuth2 認証
- ユーザーは Google アカウントを使用してログイン・新規登録が可能
- 既存のメール/パスワード認証と併用可能
- セキュアな OAuth2 フローの実装

### 2. アカウントリンク機能
- 同じメールアドレスで既にアカウントが存在する場合、自動的にリンク
- 既存ユーザーが Google ログインを使用開始できる

### 3. パスワードレス認証
- Google ログインユーザーはパスワード設定不要
- セキュリティはGoogle側で管理

## 追加されたファイル

### コントローラー
- `app/controllers/users/omniauth_callbacks_controller.rb`
  - Google OAuth コールバックを処理
  - 認証成功/失敗のハンドリング

### マイグレーション
- `db/migrate/20251010000000_add_omniauth_to_users.rb`
  - `provider` カラム追加（認証プロバイダー名）
  - `uid` カラム追加（プロバイダーのユーザーID）
  - ユニークインデックス追加

### ビュー
- `app/views/devise/shared/_links.html.erb` - Google ログインボタン
- `app/views/devise/sessions/new.html.erb` - ログインページ更新
- `app/views/devise/registrations/new.html.erb` - 新規登録ページ更新

### 設定ファイル
- `.env.development.example` - 環境変数のテンプレート
- `config/initializers/devise.rb` - OmniAuth 設定追加
- `config/routes.rb` - omniauth_callbacks ルート追加

### テストファイル
- `spec/model/user_spec.rb` - OAuth 機能のテスト追加
- `spec/factories/users.rb` - OAuth ユーザーのファクトリー追加

## セットアップ手順

### 1. Google Cloud Console での設定

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. プロジェクトを作成または選択
3. 「APIとサービス」→「認証情報」を開く
4. 「認証情報を作成」→「OAuth 2.0 クライアントID」を選択
5. アプリケーションの種類で「ウェブアプリケーション」を選択
6. 承認済みのリダイレクトURIに以下を追加：
   - 開発環境: `http://localhost:3000/users/auth/google_oauth2/callback`
   - 本番環境: `https://your-domain.com/users/auth/google_oauth2/callback`

### 2. 環境変数の設定

`.env.development.example` を `.env.development` にコピーして編集：

```bash
cp .env.development.example .env.development
```

取得したクライアントIDとシークレットを設定：

```env
GOOGLE_CLIENT_ID=your_actual_client_id_here
GOOGLE_CLIENT_SECRET=your_actual_client_secret_here
```

### 3. データベースマイグレーション

```bash
rails db:migrate
```

### 4. Gem のインストール

```bash
bundle install
```

## モデルの変更

### User モデル

#### 追加されたメソッド

##### `self.from_omniauth(auth)`
OAuth 認証後のユーザー作成/検索を処理します。

**処理フロー:**
1. provider と uid でユーザーを検索
2. 見つからない場合、email でユーザーを検索
3. email で見つかった場合、provider と uid を既存ユーザーに追加（アカウントリンク）
4. 見つからない場合、新規ユーザーを作成

```ruby
User.from_omniauth(auth)
```

##### `password_required?`
OAuth ユーザーはパスワード不要にするための override メソッド。

```ruby
def password_required?
  provider.blank? && super
end
```

## UI コンポーネント

### Google ログインボタン

- Google ブランドガイドラインに準拠したデザイン
- Bootstrap スタイリングで統一感
- 日本語テキスト「Googleでログイン」
- Google 公式カラーパレットを使用したロゴ

ボタンは以下のページに表示されます：
- ログインページ (`/users/sign_in`)
- 新規登録ページ (`/users/sign_up`)

## セキュリティ考慮事項

1. **CSRF 保護**: `omniauth-rails_csrf_protection` gem により CSRF 攻撃を防止
2. **環境変数**: 認証情報は環境変数で管理（`.gitignore` で除外）
3. **ユニーク制約**: provider と uid の組み合わせにユニークインデックス
4. **パスワード生成**: OAuth ユーザーにはランダムなパスワードを自動生成

## テスト

### 実装されたテスト

#### ユーザーモデルテスト (`spec/model/user_spec.rb`)

1. **`from_omniauth` メソッド**
   - 新規ユーザー作成
   - 既存ユーザー（provider + uid）の検索
   - 既存ユーザー（email）とのアカウントリンク

2. **`password_required?` メソッド**
   - OAuth ユーザーはパスワード不要
   - 通常ユーザーはパスワード必須

### テストの実行

```bash
bundle exec rspec spec/model/user_spec.rb
```

## トラブルシューティング

### 一般的な問題

#### 1. "Invalid OAuth callback URL" エラー
- Google Cloud Console で正しいリダイレクト URI が設定されているか確認
- HTTP/HTTPS の違いに注意

#### 2. 環境変数が読み込まれない
- `.env.development` ファイルが正しく配置されているか確認
- サーバーを再起動

#### 3. "Email has already been taken" エラー
- 既存ユーザーとのアカウントリンク機能により、このエラーは自動的に解決されます
- 既存のメールアドレスで Google ログインを使用すると、アカウントが自動的にリンクされます

## 使用している Gem

- `omniauth-google-oauth2` - Google OAuth2 認証プロバイダー
- `omniauth-rails_csrf_protection` - CSRF 攻撃からの保護

## 参考リンク

- [Devise OmniAuth Documentation](https://github.com/heartcombo/devise/wiki/OmniAuth:-Overview)
- [OmniAuth Google OAuth2 Strategy](https://github.com/zquestz/omniauth-google-oauth2)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)

## ライセンスとサポート

このプロジェクトの一部として実装されています。質問や問題がある場合は、プロジェクトの Issue を作成してください。
