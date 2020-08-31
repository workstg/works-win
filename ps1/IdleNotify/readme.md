IdleNotify
================

無操作時間 (アイドルタイム) が継続したときにメールを送信する

Requirement
----------------

- PowerShell v3 later

Usage
----------------

```cmd
%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -Command "C:\Program Files\IdleNotify\IdleNotify.ps1" -WindowStyle Minimized
```

Install
----------------

1. 任意のフォルダにスクリプト本体 (IdleNitify.ps1) と設定ファイル (AdminConfig.json, mail.txt) を配置
2. 実行ユーザーのホーム ($Home) に通知先ファイル (mailaddress.txt) を配置

"mail.txt"には通知メールの内容を記載 (1行目がメールの件名、2行目以降が本文になります)  
"AdminConfig.json"はタイムアウト値とメールサーバの情報を入力

- timeout.minutes : メールを送信するまでの無操作時間 (分)
- mail.smtp : SMTPサーバ
- mail.port : SMTPサーバのTCPポート
- mail.from : 送信元メールアドレス
- mail.auth.enabled : "0"の場合はSMTP認証が無効
- mail.auth.user : SMTP認証ユーザー
- mail.auth.password : SMTP認証パスワード
- mail.auth.ssl : "0"の場合はSSL暗号化を無効

"mailaddress.txt"ファイルは1行目に通知先のメールアドレスを入力 (2行目以降は無視されます)  

メールの送信に失敗すると、実行ユーザーのホームに"warn.log"ファイルが作成され、エラーメッセージを保存する
