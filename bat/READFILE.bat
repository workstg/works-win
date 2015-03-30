@ECHO OFF
REM
REM 外部設定ファイルの読み込みサンプル
REM

REM カレントフォルダの移動
PUSHD %0\..
CLS

REM "userlist.txt"の読み込み
FOR /F "usebackq delims== tokens=1,2" %%a IN ("userlist.txt") DO SET %%a=%%b

ECHO %USERID01% %PASSWD01%
ECHO %USERID02% %PASSWD02%

EXIT
