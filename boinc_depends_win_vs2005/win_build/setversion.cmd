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

rem Save the currently set version number to the various files used in
rem the product which are used to display version information.

IF NOT DEFINED BUILDROOT (
    ECHO BOINC build environment not detected, please execute buildenv.cmd...
    EXIT /B 1
)

SET VERSION=%BUILDVERSIONMAJOR%.%BUILDVERSIONMINOR%.%BUILDVERSIONREVISION%
SET VERSIONMAJOR=%BUILDVERSIONMAJOR%
SET VERSIONMINOR=%BUILDVERSIONMINOR%
SET VERSIONREVISION=%BUILDVERSIONREVISION%

ECHO Setting version information...
ECHO   Version: %VERSION%

ECHO   Updating version.log...
ECHO %VERSION%>"%BUILDROOT%\version.log"

ECHO   Updating configure.ac...
SET SEDEXPRESSION=s/^AC_INIT.*/AC_INIT(BOINC, %VERSION%)/
CALL :SEDEX "%BUILDROOT%\configure.ac"
IF ERRORLEVEL 1 (
    GOTO :ERRORCONFIGURE
    rem Fail
    EXIT /B %ERRORLEVEL%
)

ECHO   Updating version.h...
copy /y "%BUILDROOT%\version.h.in" "%BUILDROOT%\version.h" > NUL: 2> NUL:
CALL :SEDREPLACE "%BUILDROOT%\version.h" "@BOINC_MAJOR_VERSION@" "%VERSIONMAJOR%"
CALL :SEDREPLACE "%BUILDROOT%\version.h" "@BOINC_MINOR_VERSION@" "%VERSIONMINOR%"
CALL :SEDREPLACE "%BUILDROOT%\version.h" "@BOINC_RELEASE@" "%VERSIONREVISION%"
CALL :SEDREPLACE "%BUILDROOT%\version.h" "@BOINC_VERSION_STRING@" "%VERSION%"
CALL :SEDREPLACE "%BUILDROOT%\version.h" "@PACKAGE@" "boinc"
CALL :SEDREPLACE "%BUILDROOT%\version.h" "@PACKAGE_BUGREPORT@" "boinc_dev@ssl.berkeley.edu"
CALL :SEDREPLACE "%BUILDROOT%\version.h" "@PACKAGE_NAME@" "BOINC"
CALL :SEDREPLACE "%BUILDROOT%\version.h" "@PACKAGE_STRING@" "BOINC %VERSION%"
CALL :SEDREPLACE "%BUILDROOT%\version.h" "@PACKAGE_TARNAME@" "boinc"
CALL :SEDREPLACE "%BUILDROOT%\version.h" "@PACKAGE_VERSION@" "%VERSION%"
IF ERRORLEVEL 1 (
    GOTO :ERRORVERSION
    rem Fail
    EXIT /B %ERRORLEVEL%
)

rem Success
EXIT /B 0

:SEDREPLACE
rem '%1' - is the file
rem '%2' - value we are looking for
rem '%3' - value we are replacing it with

FOR /F "usebackq delims=" %%I IN ('%1') DO SET SEDFILE=%%~I
FOR /F "usebackq delims=" %%I IN ('%2') DO SET SEDFIND=%%~I
FOR /F "usebackq delims=" %%I IN ('%3') DO SET SEDREPLACE=%%~I

move /y %SEDFILE% %SEDFILE%.old > NUL: 2> NUL:
IF ERRORLEVEL 1 EXIT /B 1

sed "s/%SEDFIND%/%SEDREPLACE%/g" %SEDFILE%.old > %SEDFILE%
IF ERRORLEVEL 1 EXIT /B 1

del %SEDFILE%.old > NUL: 2> NUL:
IF ERRORLEVEL 1 EXIT /B 1
EXIT /B 0

:SEDEX
rem Ateempting to pass some sed expressions as a parameter appears to cause
rem some sort of encoding/decoding problem. So use a global SEDEXPRESSION variable
rem instead.
rem '%1' - is the file

FOR /F "usebackq delims=" %%I IN ('%1') DO SET SEDFILE=%%~I

move /y %SEDFILE% %SEDFILE%.old > NUL: 2> NUL:
IF ERRORLEVEL 1 EXIT /B 1

sed "%SEDEXPRESSION%" %SEDFILE%.old > %SEDFILE%
IF ERRORLEVEL 1 EXIT /B 1

del %SEDFILE%.old > NUL: 2> NUL:
IF ERRORLEVEL 1 EXIT /B 1
EXIT /B 0

:ERRORCONFIGURE
ECHO    Failed to update configure.ac
EXIT /B 1

:ERRORVERSION
ECHO    Failed to update version.h
EXIT /B 2
