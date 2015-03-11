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

rem Customize build environment to your tastes

rem Setup color scheme
IF /I "%BUILDTYPE%" == "Release" COLOR 17
IF /I "%BUILDTYPE%" == "Debug" COLOR 27

rem Read custom dictionary
FOR /F "usebackq tokens=1,2 delims==" %%I IN (%BUILDHOMEDIR%\customdict.txt) DO SET %%I=%%J
