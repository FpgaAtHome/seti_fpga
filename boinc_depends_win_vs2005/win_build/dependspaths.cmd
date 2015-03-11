@IF "%BUILDDBG%"=="TRUE" ( ECHO ON ) ELSE ( ECHO OFF )
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

rem Locations to components BOINC depends on.

IF NOT DEFINED BUILDROOT (
    ECHO BOINC build environment not detected, please execute buildenv.cmd...
    EXIT /B 1
)

SET INSTALLERREDIST=%BUILDROOT%\win_build\installerv2\redist\Windows\%VSPLATFORM%
SET CURLREDIST=%BUILDTOOLSROOT%\curl\mswin\%VSPLATFORM%\%BUILDTYPE%\bin
SET CURLSUPPORT=%BUILDTOOLSROOT%\curl\
SET OPENSSLREDIST=%BUILDTOOLSROOT%\openssl\mswin\%VSPLATFORM%\%BUILDTYPE%\bin
SET ZLIBREDIST=%BUILDTOOLSROOT%\zlib\mswin\%VSPLATFORM%\%BUILDTYPE%\bin
SET SQLITEREDIST=%BUILDTOOLSROOT%\sqlite3\mswin\%VSPLATFORM%\%BUILDTYPE%\bin
