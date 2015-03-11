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

rem Build various components of the product as well as all of the product.
rem   Skips building the sample applications and components used by
rem   the projects.

IF NOT DEFINED BUILDROOT (
    echo BOINC build environment not detected, please execute buildenv.cmd...
    EXIT /B 1
)

SET VSBUILDCONF=%BUILDTYPE%^|%VSPLATFORM%

rem ***** Parse Parameters *****
rem
:PARAMCOMPONENT
IF /I "%1"=="BOINC"                         CALL :BUILDBOINC
IF /I "%1"=="BOINCMgr"                      CALL :BUILDBOINCMGR
IF /I "%1"=="BOINCCmd"                      CALL :BUILDBOINCCMD
IF /I "%1"=="BOINCScr"                      CALL :BUILDBOINCSCR
IF /I "%1"=="BOINCScrCtrl"                  CALL :BUILDBOINCSCRCTRL
IF /I "%1"=="BOINCSvcCtrl"                  CALL :BUILDBOINCSVCCTRL
IF /I "%1"=="BOINCTray"                     CALL :BUILDBOINCTRAY
IF /I "%1"=="All"                           CALL :ALL
GOTO :BUILDDONE


:ALL
ECHO Building the World...
CALL :BUILDBOINC
CALL :BUILDBOINCMGR
CALL :BUILDBOINCCMD
CALL :BUILDBOINCSCR
CALL :BUILDBOINCSCRCTRL
CALL :BUILDBOINCSVCCTRL
CALL :BUILDBOINCTRAY
GOTO :EOF


:BUILDBOINC
EHCO   Building BOINC:
devenv "%BUILDROOT%\win_build\BOINC.sln" /build "%VSBUILDCONF%" /project "boinc" > "%BUILDHOMEDIR%\temp\BuildStatus.txt"
IF ERRORLEVEL 1 CALL :BUILDFAILURE
CALL :BUILDSUCCESS
GOTO :EOF


:BUILDBOINCMGR
ECHO   Building BOINC Manager:
devenv "%BUILDROOT%\win_build\BOINC.sln" /build "%VSBUILDCONF%" /project "boincmgr" > "%BUILDHOMEDIR%\temp\BuildStatus.txt"
IF ERRORLEVEL 1 CALL :BUILDFAILURE
CALL :BUILDSUCCESS
GOTO :EOF


:BUILDBOINCCMD
ECHO   Building BOINC Command:
devenv "%BUILDROOT%\win_build\BOINC.sln" /build "%VSBUILDCONF%" /project "boinccmd" > "%BUILDHOMEDIR%\temp\BuildStatus.txt"
IF ERRORLEVEL 1 CALL :BUILDFAILURE
CALL :BUILDSUCCESS
GOTO :EOF


:BUILDBOINCSCR
ECHO   Building BOINC Screen Saver:
devenv "%BUILDROOT%\win_build\BOINC.sln" /build "%VSBUILDCONF%" /project "boinc_ss" > "%BUILDHOMEDIR%\temp\BuildStatus.txt"
IF ERRORLEVEL 1 CALL :BUILDFAILURE
CALL :BUILDSUCCESS
GOTO :EOF


:BUILDBOINCSCRCTRL
ECHO   Building BOINC Screen Saver Controller:
devenv "%BUILDROOT%\win_build\BOINC.sln" /build "%VSBUILDCONF%" /project "ss_app" > "%BUILDHOMEDIR%\temp\BuildStatus.txt"
IF ERRORLEVEL 1 CALL :BUILDFAILURE
CALL :BUILDSUCCESS
GOTO :EOF


:BUILDBOINCSVCCTRL
ECHO   Building BOINC Service Controller:
devenv "%BUILDROOT%\win_build\BOINC.sln" /build "%VSBUILDCONF%" /project "boincsvcctrl" > "%BUILDHOMEDIR%\temp\BuildStatus.txt"
IF ERRORLEVEL 1 CALL :BUILDFAILURE
CALL :BUILDSUCCESS
GOTO :EOF


:BUILDBOINCTRAY
ECHO   Building BOINC System Tray:
devenv "%BUILDROOT%\win_build\BOINC.sln" /build "%VSBUILDCONF%" /project "boinctray" > "%BUILDHOMEDIR%\temp\BuildStatus.txt"
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