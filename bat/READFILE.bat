@ECHO OFF
REM
REM �O���ݒ�t�@�C���̓ǂݍ��݃T���v��
REM

REM �J�����g�t�H���_�̈ړ�
PUSHD %0\..
CLS

REM "userlist.txt"�̓ǂݍ���
FOR /F "usebackq delims== tokens=1,2" %%a IN ("userlist.txt") DO SET %%a=%%b

ECHO %USERID01% %PASSWD01%
ECHO %USERID02% %PASSWD02%

EXIT
