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

rem Update any DLLs in the output directory that the various components of
rem BOINC depend on.

IF NOT DEFINED BUILDROOT (
    ECHO BOINC build environment not detected, please execute buildenv.cmd...
    EXIT /B 1
)

rem Get the paths to the various components
CALL DEPENDSPATHS.CMD

CALL :UPDATELIB "All" "%BUILDTYPE%" "dbghelp.dll" "%INSTALLERREDIST%" "%BUILDOUTPUT%"
IF ERRORLEVEL 1 (
    rem Fail
    EXIT /B %ERRORLEVEL%
)

CALL :UPDATELIB "All" "%BUILDTYPE%" "dbghelp95.dll" "%INSTALLERREDIST%" "%BUILDOUTPUT%"
IF ERRORLEVEL 1 (
    rem Fail
    EXIT /B %ERRORLEVEL%
)

CALL :UPDATELIB "All" "%BUILDTYPE%" "symsrv.dll" "%INSTALLERREDIST%" "%BUILDOUTPUT%"
IF ERRORLEVEL 1 (
    rem Fail
    EXIT /B %ERRORLEVEL%
)

CALL :UPDATELIB "All" "%BUILDTYPE%" "symsrv.yes" "%INSTALLERREDIST%" "%BUILDOUTPUT%"
IF ERRORLEVEL 1 (
    rem Fail
    EXIT /B %ERRORLEVEL%
)

CALL :UPDATELIB "All" "%BUILDTYPE%" "srcsrv.dll" "%INSTALLERREDIST%" "%BUILDOUTPUT%"
IF ERRORLEVEL 1 (
    rem Fail
    EXIT /B %ERRORLEVEL%
)

CALL :UPDATELIB "Debug" "%BUILDTYPE%" "libcurld.dll" "%CURLREDIST%" "%BUILDOUTPUT%"
IF ERRORLEVEL 1 (
    rem Fail
    EXIT /B %ERRORLEVEL%
)

CALL :UPDATELIB "Release" "%BUILDTYPE%" "libcurl.dll" "%CURLREDIST%" "%BUILDOUTPUT%"
IF ERRORLEVEL 1 (
    rem Fail
    EXIT /B %ERRORLEVEL%
)

CALL :UPDATELIB "All" "%BUILDTYPE%" "ca-bundle.crt" "%CURLSUPPORT%" "%BUILDOUTPUT%"
IF ERRORLEVEL 1 (
    rem Fail
    EXIT /B %ERRORLEVEL%
)

CALL :UPDATELIB "All" "%BUILDTYPE%" "libeay32.dll" "%OPENSSLREDIST%" "%BUILDOUTPUT%"
IF ERRORLEVEL 1 (
    rem Fail
    EXIT /B %ERRORLEVEL%
)

CALL :UPDATELIB "All" "%BUILDTYPE%" "ssleay32.dll" "%OPENSSLREDIST%" "%BUILDOUTPUT%"
IF ERRORLEVEL 1 (
    rem Fail
    EXIT /B %ERRORLEVEL%
)

CALL :UPDATELIB "Debug" "%BUILDTYPE%" "zlib1d.dll" "%ZLIBREDIST%" "%BUILDOUTPUT%"
IF ERRORLEVEL 1 (
    rem Fail
    EXIT /B %ERRORLEVEL%
)

CALL :UPDATELIB "Release" "%BUILDTYPE%" "zlib1.dll" "%ZLIBREDIST%" "%BUILDOUTPUT%"
IF ERRORLEVEL 1 (
    rem Fail
    EXIT /B %ERRORLEVEL%
)

CALL :UPDATELIB "All" "%BUILDTYPE%" "sqlite3.dll" "%SQLITEREDIST%" "%BUILDOUTPUT%"
IF ERRORLEVEL 1 (
    rem Fail
    EXIT /B %ERRORLEVEL%
)

rem Success
EXIT /B 0


:UPDATELIB
rem '%1' - Configuration Supported (All, Debug, Release)
rem '%2' - Current Configuration
rem '%3' - Library
rem '%4' - Source Directory
rem '%5' - Target Directory

FOR /F "usebackq delims=" %%I IN ('%1') DO SET CONFIGURATIONSUPPORTED=%%~I
FOR /F "usebackq delims=" %%I IN ('%2') DO SET CONFIGURATIONNAME=%%~I
FOR /F "usebackq delims=" %%I IN ('%3') DO SET LIBRARY=%%~I
FOR /F "usebackq delims=" %%I IN ('%4') DO SET SOURCEDIR=%%~I
FOR /F "usebackq delims=" %%I IN ('%5') DO SET DESTDIR=%%~I
FOR /F "usebackq tokens=5 delims= " %%I IN (`filever "!SOURCEDIR!\!LIBRARY!"`) DO SET SOURCEVERSION=%%~I
FOR /F "usebackq tokens=5 delims= " %%I IN (`filever "!DESTDIR!\!LIBRARY!"`) DO SET DESTVERSION=%%~I

rem Check platform
IF /I "!CONFIGURATIONSUPPORTED!" == "All" GOTO :CONFIGURATIONCHECKSUCCESSFUL
IF /I "!CONFIGURATIONSUPPORTED!" == "!CONFIGURATIONNAME!" GOTO :CONFIGURATIONCHECKSUCCESSFUL
EXIT /B 0
:CONFIGURATIONCHECKSUCCESSFUL

rem If a version mismatch, copy the file.
IF NOT "!SOURCEVERSION!" == "!DESTVERSION!" GOTO :COPYLIB

rem If the file is missing, copy the file.
IF NOT EXIST !DESTDIR!\!LIBRRAY! GOTO :COPYLIB

EXIT /B 0

:COPYLIB
ECHO Copying !LIBRARY!(!SOURCEVERSION!) to the output directory...
copy /y "!SOURCEDIR!\!LIBRARY!" "!DESTDIR!\!LIBRRAY!" > NUL: 2> NUL:
EXIT /B !ERRORLEVEL!