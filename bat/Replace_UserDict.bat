@ECHO OFF
 
SETLOCAL
REM ------------------------------------------------------------
REM IME14 �����t�@�C���̃��W�X�g��
SET KEY=HKEY_CURRENT_USER\Software\Microsoft\IMEJP\14.0\Dictionaries
SET VALNAME=DIC00
 
REM �����t�@�C���̈ړ���
SET DATA=%USERPROFILE%\Microsoft\IMJP14\imjp14cu.dic,1
 
REM �����t�@�C���̊���̏ꏊ
SET SOURCEDIC=%APPDATA%\Microsoft\IMJP14\imjp14cu.dic
REM ------------------------------------------------------------
 
REM Windows XP�Ȃ牽�������ɏI��
FOR /f "tokens=3 delims= " %%I IN ( 'ver') DO SET VER=%%I
IF "%VER%" == "XP" (
EXIT 0
)
 
REM (�ݒ�ς݃`�F�b�N) ���Ɋ������Ă�����A���������ɏI��
FOR /F "tokens=3 delims= " %%I in ('reg query "%KEY%" /v "%VALNAME%"') DO SET RESULT=%%I
IF "%RESULT%" == "%DATA%" (
EXIT 0
)
 
REM IME14 �����t�@�C�����ړ��i���W�X�g���ύX)
reg add "%KEY%" /v "%VALNAME%" /d "%DATA%" /f
mkdir %USERPROFILE%\Microsoft\IMJP14\
REM ����̏ꏊ�Ƀt�@�C�������݂��Ă���ꍇ�̓R�s�[
IF EXIST %SOURCEDIC% (
xcopy /D /H /Y /R %SOURCEDIC% %USERPROFILE%\Microsoft\IMJP14\
)
 
exit 0