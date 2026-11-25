:: Set source and destination directories
set source_dir=src
set dest_dir=output/

:: Loop through all .ls files in the source directory
for %%f in ("%source_dir%\*.ls") do (
    set "filename=%%~nxf"
    call :check_and_compile
)
echo All specified files have been compiled.
goto :eof

:check_and_compile
echo Compiling: %filename%
maketp "%source_dir%\%filename%" "%dest_dir%"
goto :eof