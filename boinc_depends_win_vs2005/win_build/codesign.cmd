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

IF NOT DEFINED BUILDROOT (
    ECHO BOINC build environment not detected, please execute buildenv.cmd...
    EXIT /B 1
)

IF NOT DEFINED BUILDCODESIGN (
    ECHO BOINC build environment not configured for code signing, contact the development team...
    EXIT /B 2
)


signtool sign /f "%BUILDCODESIGN%\boinc.pfx" /p "%CODESIGNBOINC%" /d "BOINC Client Software" /du "http://boinc.berkeley.edu" /t "http://timestamp.verisign.com/scripts/timstamp.dll" "%BUILDOUTPUT%\boinc.scr"
signtool sign /f "%BUILDCODESIGN%\boinc.pfx" /p "%CODESIGNBOINC%" /d "BOINC Client Software" /du "http://boinc.berkeley.edu" /t "http://timestamp.verisign.com/scripts/timstamp.dll" "%BUILDOUTPUT%\boinc.exe"
signtool sign /f "%BUILDCODESIGN%\boinc.pfx" /p "%CODESIGNBOINC%" /d "BOINC Client Software" /du "http://boinc.berkeley.edu" /t "http://timestamp.verisign.com/scripts/timstamp.dll" "%BUILDOUTPUT%\boinccmd.exe"
signtool sign /f "%BUILDCODESIGN%\boinc.pfx" /p "%CODESIGNBOINC%" /d "BOINC Client Software" /du "http://boinc.berkeley.edu" /t "http://timestamp.verisign.com/scripts/timstamp.dll" "%BUILDOUTPUT%\boincscr.exe"
signtool sign /f "%BUILDCODESIGN%\boinc.pfx" /p "%CODESIGNBOINC%" /d "BOINC Client Software" /du "http://boinc.berkeley.edu" /t "http://timestamp.verisign.com/scripts/timstamp.dll" "%BUILDOUTPUT%\boinctray.exe"
signtool sign /f "%BUILDCODESIGN%\boinc.pfx" /p "%CODESIGNBOINC%" /d "BOINC Client Software" /du "http://boinc.berkeley.edu" /t "http://timestamp.verisign.com/scripts/timstamp.dll" "%BUILDOUTPUT%\boincsvcctrl.exe"
signtool sign /f "%BUILDCODESIGN%\boinc.pfx" /p "%CODESIGNBOINC%" /d "BOINC Client Software" /du "http://boinc.berkeley.edu" /t "http://timestamp.verisign.com/scripts/timstamp.dll" "%BUILDOUTPUT%\boincmgr.exe"
