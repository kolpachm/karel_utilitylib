@echo off
setlocal

:: ===========================================================================
::  FANUC build script - compiles TP (*.ls) and KAREL (*.kl) sources
::  KAREL header files (*_h.kl) are excluded from compilation.
::  The stray .pc that ktrans leaves in the working directory is removed
::  after a verified successful compile.
::
::  NOTE ON PATHS:
::  dest_dir MUST NOT end with a backslash when it is passed inside quotes.
::  The C runtime treats \" as an escaped quote, so "output\" reaches the
::  compiler as  output"  -> Windows error 123 (invalid name).
::  A trailing forward slash is safe and is accepted by the Win32 API.
:: ===========================================================================

:: --- Configuration ---------------------------------------------------------
:: %~dp0 = directory of this script, already terminated with a backslash.
set "script_dir=%~dp0"
set "source_dir=%script_dir%src"
set "out_path=%script_dir%output"
set "dest_dir=%out_path%/"

set /a fail_count=0
set /a ok_count=0
set /a skip_count=0

:: --- Sanity checks ---------------------------------------------------------
if not exist "%source_dir%\" (
    echo ERROR: Source directory "%source_dir%" does not exist.
    endlocal & exit /b 1
)

if not exist "%out_path%\" (
    echo Creating output directory: %out_path%
    mkdir "%out_path%" || (
        echo ERROR: Could not create output directory.
        endlocal & exit /b 1
    )
)

echo Source: %source_dir%
echo Output: %out_path%
echo.

:: --- Compile TP programs ---------------------------------------------------
for %%f in ("%source_dir%\*.ls") do (
    set "filename=%%~nxf"
    set "basename=%%~nf"
    call :compile_tp
)

:: --- Compile KAREL programs ------------------------------------------------
for %%f in ("%source_dir%\*.kl") do (
    set "filename=%%~nxf"
    set "basename=%%~nf"
    call :compile_kl
)

:: --- Summary ---------------------------------------------------------------
echo.
echo ---------------------------------------------------------------
echo  Compiled: %ok_count%   Skipped: %skip_count%   Failed: %fail_count%
echo ---------------------------------------------------------------

if %fail_count% GTR 0 (
    echo BUILD FAILED.
) else (
    echo Build completed successfully.
)

endlocal & exit /b %fail_count%


:: ===========================================================================
::  Subroutines
::  Called per file so that %filename% is expanded at call time - this avoids
::  the need for delayed expansion inside the FOR blocks.
:: ===========================================================================

:compile_tp
echo Compiling TP:    %filename%
:: Remove any stale artifact so that the existence test below is meaningful.
if exist "%out_path%\%basename%.tp" del /q "%out_path%\%basename%.tp"
maketp "%source_dir%\%filename%" "%dest_dir%"
call :verify "%out_path%\%basename%.tp"
goto :eof


:compile_kl
:: Header test - strict "_h" suffix on the base name.
:: To exclude any file merely *containing* "_h", comment out the line below
:: and uncomment the alternative.
if /i "%basename:~-2%"=="_h" (
::if not "%filename%"=="%filename:_h=%" (
    echo Skipping header: %filename%
    set /a skip_count+=1
    goto :eof
)
echo Compiling KAREL: %filename%
if exist "%out_path%\%basename%.pc" del /q "%out_path%\%basename%.pc"
ktrans "%source_dir%\%filename%" "%dest_dir%"
call :verify "%out_path%\%basename%.pc"
:: ktrans translates into the working directory and then copies the result to
:: the destination; the working-directory copy is left behind. Remove it.
call :clean_stray "%basename%.pc" "%out_path%\%basename%.pc"
goto :eof


:verify
:: %~1 = full path of the artifact that must exist after a successful compile.
:: The FANUC tools do not reliably return a non-zero exit code (ktrans can
:: print "Translation successful" and still fail to copy the .pc), so the
:: presence of the output file is the authoritative result.
if exist "%~1" (
    set /a ok_count+=1
) else (
    echo   *** FAILED: %filename%  ^(no output at "%~1"^)
    set /a fail_count+=1
)
goto :eof


:clean_stray
:: %~1 = bare artifact name left in the current working directory
:: %~2 = full path of the real artifact in the output directory
:: Guard 1: only delete once the real output exists, so a failed copy never
::          destroys the only surviving copy of the compiled file.
:: Guard 2: never delete when the working directory IS the output directory,
::          which would remove the deliverable itself.
if not exist "%~2" goto :eof
set "stray=%CD%\%~1"
if /i "%stray%"=="%~f2" goto :eof
if exist "%stray%" (
    del /q "%stray%"
    echo   Removed stray: %~1
)
goto :eof
