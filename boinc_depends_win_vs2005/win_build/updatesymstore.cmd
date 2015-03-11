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

rem Take the current batch of BOINC PDB files and add them to the
rem local symstore.

IF NOT DEFINED BUILDROOT (
    ECHO BOINC build environment not detected, please execute buildenv.cmd...
    EXIT /B 1
)

rem ***** Parse Parameters *****
rem
:PARAMCOMPONENT
IF /I "%1"==""                           CALL :ALL
GOTO :BUILDDONE


:ALL
ECHO   Adding BOINC symbols to symbol store...
CALL :UPDATEDEPENDS "BOINC" "boinc.exe" "%BUILDOUTPUT%"
IF ERRORLEVEL 1 CALL :BUILDFAILURE
CALL :BUILDSUCCESS
GOTO :EOF


:BUILDDONE
IF /I "%VSBUILDFAILURE%"=="TRUE" EXIT /B 10
GOTO :EOF


:UPDATEDEPENDS
rem %1 - Module Name
rem %2 - Module Filename (for file version check)
rem %3 - Source Directory

FOR /F "usebackq delims=" %%I IN ('%1') DO SET MODULENAME=%%~I
FOR /F "usebackq delims=" %%I IN ('%2') DO SET MODULEFILENAME=%%~I
FOR /F "usebackq delims=" %%I IN ('%3') DO SET SOURCEDIR=%%~I

ECHO     Checking version...
FOR /F "usebackq tokens=5 delims= " %%I IN (`filever "!SOURCEDIR!\!MODULEFILENAME!"`) DO SET MODULEVERSION=%%~I
IF /I "!MODULEVERSION!" == "-" EXIT /B 1

ECHO     Checking symbols...
symchk /q /s "!SOURCEDIR!" /if *.pdb
IF ERRORLEVEL 1 EXIT /B 1

ECHO     Adding symbols to symstore...
symstore.exe add /l /f "!SOURCEDIR!\*.pdb" /s "!BUILDSYMBOLSTORE!" /compress /t "!MODULENAME! !BUILDPLATFORM!" /v "!MODULEVERSION!" /o /c "Application Release" > "!BUILDHOMEDIR!\temp\SymstoreStatus.txt"
IF ERRORLEVEL 1 EXIT /B 1
GOTO :EOF


:BUILDSUCCESS
ECHO     Success
GOTO :EOF


:BUILDFAILURE
SET VSBUILDFAILURE=TRUE
ECHO     Failure
ECHO Build Log Below:
TYPE "%BUILDHOMEDIR%\temp\SymstoreStatus.txt"
GOTO :EOF