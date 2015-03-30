'設定ファイル
'ドメイン名
Const Domain = "example.com"

'パスワード変更通知期限（この日数以下になるとユーザーへ通知します）
Const NotifyLimit = 7

'メール送信設定
'SMTPサーバ
Const SmtpServer = "smtp.example.com"

'送信元メールアドレス（From）
Const MailFrom = "admin@example.com"

'メール件名
Const MailSubJect = "[重要] パスワードを更新してください"

'既定のメールアドレス（ユーザーのメールアドレスが未登録の場合はこのアドレスへ通知）
Const DefaultTo = "postmaster@example.com"

'SMTP認証の有効(True)/無効(False)
Const EnableSmtpAuth = True

'SMTP認証情報
Const SmtpUser = "postmaster"
Const SmtpPassword = "password"

'除外ユーザー（セミコロン区切りでユーザー名を記載）
Const ExcludeUser = "Administrator;krbtgt"
