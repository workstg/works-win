@ECHO OFF
 
SETLOCAL
REM ------------------------------------------------------------
REM IME14 辞書ファイルのレジストリ
SET KEY=HKEY_CURRENT_USER\Software\Microsoft\IMEJP\14.0\Dictionaries
SET VALNAME=DIC00
 
REM 辞書ファイルの移動先
SET DATA=%USERPROFILE%\Microsoft\IMJP14\imjp14cu.dic,1
 
REM 辞書ファイルの既定の場所
SET SOURCEDIC=%APPDATA%\Microsoft\IMJP14\imjp14cu.dic
REM ------------------------------------------------------------
 
REM Windows XPなら何もせずに終了
FOR /f "tokens=3 delims= " %%I IN ( 'ver') DO SET VER=%%I
IF "%VER%" == "XP" (
EXIT 0
)
 
REM (設定済みチェック) 既に完了していたら、何もせずに終了
FOR /F "tokens=3 delims= " %%I in ('reg query "%KEY%" /v "%VALNAME%"') DO SET RESULT=%%I
IF "%RESULT%" == "%DATA%" (
EXIT 0
)
 
REM IME14 辞書ファイルを移動（レジストリ変更)
reg add "%KEY%" /v "%VALNAME%" /d "%DATA%" /f
mkdir %USERPROFILE%\Microsoft\IMJP14\
REM 既定の場所にファイルが存在している場合はコピー
IF EXIST %SOURCEDIC% (
xcopy /D /H /Y /R %SOURCEDIC% %USERPROFILE%\Microsoft\IMJP14\
)
 
exit 0