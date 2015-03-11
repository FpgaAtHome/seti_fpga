@IF "%BUILDDBG%"=="TRUE" ( ECHO ON ) ELSE ( ECHO OFF )
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
rem Berkeley Open Infrastructure for Network Computing
rem http://boinc.berkeley.edu
rem Copyright (C) 2009 University of California
rem 
rem This is free software; you can redistribute it and/or
rem modify it under the terms of the GNU Lesser General Public
rem License as published by the Free Software Foundation;
rem either version 3 of the License, or (at your option) any later version.
rem 
rem This software is distributed in the hope that it will be useful,
rem but WITHOUT ANY WARRANTY; without even the implied warranty of
rem MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
rem See the GNU Lesser General Public License for more details.
rem 
rem You should have received a copy of the GNU Lesser General Public License
rem along with BOINC.  If not, see <http://www.gnu.org/licenses/>.
rem

rem Cleans up from the last build one component at a time or all the
rem components.

IF NOT DEFINED BUILDROOT (
    echo BOINC build environment not detected, please execute buildenv.cmd...
    EXIT /B 1
)

SET VSBUILDCONF=%BUILDTYPE%^|%VSPLATFORM%

rem ***** Parse Parameters *****
rem
:PARAMCOMPONENT
IF /I "%1"=="BOINC"                         CALL :CLEANBOINC
IF /I "%1"=="BOINCMgr"                      CALL :CLEANBOINCMGR
IF /I "%1"=="BOINCCmd"                      CALL :CLEANBOINCCMD
IF /I "%1"=="BOINCScr"                      CALL :CLEANBOINCSCR
IF /I "%1"=="BOINCScrCtrl"                  CALL :CLEANBOINCSCRCTRL
IF /I "%1"=="BOINCSvcCtrl"                  CALL :CLEANBOINCSVCCTRL
IF /I "%1"=="BOINCTray"                     CALL :CLEANBOINCTRAY
IF /I "%1"=="All"                           CALL :ALL
GOTO :BUILDDONE


:ALL
ECHO Cleaning up the World...
devenv "%BUILDROOT%\win_build\BOINC.sln" /clean "%VSBUILDCONF%" > "%BUILDHOMEDIR%\temp\BuildStatus.txt"
IF ERRORLEVEL 1 CALL :BUILDFAILURE
CALL :BUILDSUCCESS
GOTO :EOF


:CLEANBOINC
ECHO   Cleaning BOINC:
devenv "%BUILDROOT%\win_build\BOINC.sln" /clean "%VSBUILDCONF%" /project "boinc" > "%BUILDHOMEDIR%\temp\BuildStatus.txt"
IF ERRORLEVEL 1 CALL :BUILDFAILURE
CALL :BUILDSUCCESS
GOTO :EOF


:CLEANBOINCMGR
ECHO   Cleaning BOINC Manager:
devenv "%BUILDROOT%\win_build\BOINC.sln" /clean "%VSBUILDCONF%" /project "boincmgr" > "%BUILDHOMEDIR%\temp\BuildStatus.txt"
IF ERRORLEVEL 1 CALL :BUILDFAILURE
CALL :BUILDSUCCESS
GOTO :EOF


:CLEANBOINCCMD
ECHO   Cleaning BOINC Command:
devenv "%BUILDROOT%\win_build\BOINC.sln" /clean "%VSBUILDCONF%" /project "boinccmd" > "%BUILDHOMEDIR%\temp\BuildStatus.txt"
IF ERRORLEVEL 1 CALL :BUILDFAILURE
CALL :BUILDSUCCESS
GOTO :EOF


:CLEANBOINCSCR
ECHO   Cleaning BOINC Screen Saver:
devenv "%BUILDROOT%\win_build\BOINC.sln" /clean "%VSBUILDCONF%" /project "boinc_ss" > "%BUILDHOMEDIR%\temp\BuildStatus.txt"
IF ERRORLEVEL 1 CALL :BUILDFAILURE
CALL :BUILDSUCCESS
GOTO :EOF


:CLEANBOINCSCRCTRL
ECHO   Cleaning BOINC Screen Saver Controller:
devenv "%BUILDROOT%\win_build\BOINC.sln" /clean "%VSBUILDCONF%" /project "ss_app" > "%BUILDHOMEDIR%\temp\BuildStatus.txt"
IF ERRORLEVEL 1 CALL :BUILDFAILURE
CALL :BUILDSUCCESS
GOTO :EOF


:CLEANBOINCSVCCTRL
ECHO   Cleaning BOINC Service Controller:
devenv "%BUILDROOT%\win_build\BOINC.sln" /clean "%VSBUILDCONF%" /project "boincsvcctrl" > "%BUILDHOMEDIR%\temp\BuildStatus.txt"
IF ERRORLEVEL 1 CALL :BUILDFAILURE
CALL :BUILDSUCCESS
GOTO :EOF


:CLEANBOINCTRAY
ECHO   Cleaning BOINC System Tray:
devenv "%BUILDROOT%\win_build\BOINC.sln" /clean "%VSBUILDCONF%" /project "boinctray" > "%BUILDHOMEDIR%\temp\BuildStatus.txt"
IF ERRORLEVEL 1 CALL :BUILDFAILURE
CALL :BUILDSUCCESS
GOTO :EOF


:BUILDDONE
IF /I "%VSBUILDFAILURE%"=="TRUE" EXIT /B 10
GOTO :EOF


:BUILDSUCCESS
ECHO     Success
GOTO :EOF


:BUILDFAILURE
SET VSBUILDFAILURE=TRUE
ECHO     Failure
ECHO Build Log Below:
TYPE "%BUILDHOMEDIR%\temp\BuildStatus.txt"
GOTO :EOF