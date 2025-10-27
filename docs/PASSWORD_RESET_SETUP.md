# パスワードリセット機能のセットアップガイド

## 概要

本番環境でパスワードリセット機能を有効にするためのガイドです。この機能により、ユーザーはメールを介してパスワードをリセットできます。

## 必要な環境変数

本番環境（Render等）で以下の環境変数を設定してください：

| 環境変数名 | 説明 | 例 |
|-----------|------|-----|
| `SMTP_ADDRESS` | SMTPサーバーのアドレス | `smtp.gmail.com` |
| `SMTP_PORT` | SMTPポート番号 | `587` |
| `SMTP_DOMAIN` | アプリケーションのドメイン | `app-loopin.com` |
| `SMTP_USERNAME` | SMTP認証用のユーザー名（通常はメールアドレス） | `your-email@gmail.com` |
| `SMTP_PASSWORD` | SMTP認証用のパスワード | `your-app-password` |
| `SMTP_AUTHENTICATION` | 認証方式 | `plain` |
| `SMTP_ENABLE_STARTTLS_AUTO` | STARTTLS自動有効化 | `true` |

## Gmail を使用する場合

### 1. Googleアカウントで2段階認証を有効化
1. [Googleアカウント](https://myaccount.google.com/)にログイン
2. 「セキュリティ」→「2段階認証プロセス」を有効化

### 2. アプリパスワードの生成
1. [アプリパスワード](https://myaccount.google.com/apppasswords)にアクセス
2. アプリ名を入力（例：「Loopin Production」）
3. 「生成」をクリック
4. 生成された16文字のパスワードをコピー

### 3. Renderで環境変数を設定
1. Renderダッシュボードにログイン
2. アプリケーションを選択
3. 「Environment」タブを開く
4. 以下の環境変数を追加：
   ```
   SMTP_ADDRESS=smtp.gmail.com
   SMTP_PORT=587
   SMTP_DOMAIN=app-loopin.com
   SMTP_USERNAME=your-email@gmail.com
   SMTP_PASSWORD=生成したアプリパスワード
   SMTP_AUTHENTICATION=plain
   SMTP_ENABLE_STARTTLS_AUTO=true
   ```
5. 「Save Changes」をクリック
6. アプリケーションが自動的に再デプロイされます

## その他のSMTPプロバイダー

### SendGrid
```
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
```

### Mailgun
```
SMTP_ADDRESS=smtp.mailgun.org
SMTP_PORT=587
SMTP_USERNAME=postmaster@your-domain.mailgun.org
SMTP_PASSWORD=your-mailgun-password
```

### Amazon SES
```
SMTP_ADDRESS=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
SMTP_USERNAME=your-ses-smtp-username
SMTP_PASSWORD=your-ses-smtp-password
```

## 使用方法

### ユーザー側の操作
1. ログインページにアクセス
2. 「パスワードを忘れた方はこちら」リンクをクリック
3. 登録済みのメールアドレスを入力
4. 「パスワード再設定メールを送信」ボタンをクリック
5. メールに記載されたリンクをクリック
6. 新しいパスワードを入力して設定

### 管理者による確認
- 開発環境では、`letter_opener_web`が有効で、メールは`/letter_opener`で確認できます
- 本番環境では、実際にメールが送信されます

## トラブルシューティング

### メールが送信されない
1. 環境変数が正しく設定されているか確認
2. SMTPパスワードが正しいか確認（Gmailの場合、通常のパスワードではなくアプリパスワードを使用）
3. Renderのログを確認：`View Logs`から配信エラーを確認

### リセットリンクが機能しない
1. リセットトークンの有効期限（6時間）を確認
2. `config.action_mailer.default_url_options`が正しいドメインを指しているか確認

### OAuthユーザー（Googleログイン）について
- OAuthで登録したユーザーはパスワードを持たないため、パスワードリセットは実質的に無効です
- しかし、セキュリティのため、リクエスト時に同じメッセージを返します

## セキュリティ考慮事項

1. **メールアドレスの存在確認**: セキュリティのため、メールアドレスが存在するかどうかにかかわらず、同じメッセージを表示します
2. **トークンの有効期限**: リセットトークンは6時間で期限切れになります
3. **HTTPS必須**: 本番環境では必ずHTTPSを使用してください（Renderではデフォルトで有効）
4. **パスワード強度**: 最低6文字以上のパスワードが必要です

## 参考リンク

- [Devise公式ドキュメント](https://github.com/heartcombo/devise)
- [Action Mailer ガイド](https://guides.rubyonrails.org/action_mailer_basics.html)
- [Gmailアプリパスワード](https://myaccount.google.com/apppasswords)
