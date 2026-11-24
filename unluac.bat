@echo off
rem Compile the current sources and run with the supplied arguments.
setlocal
set "root=%~dp0"
set "classes=%root%build\classes"

if exist "%classes%" rmdir /s /q "%classes%"
if exist "%classes%" exit /b 1
mkdir "%classes%"
if errorlevel 1 exit /b %errorlevel%
javac -d "%classes%" -sourcepath "%root%src" "%root%src\unluac\Main.java"
if errorlevel 1 exit /b %errorlevel%
java -cp "%classes%" unluac.Main %*
exit /b %errorlevel%
