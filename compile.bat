:: Set source and destination directories
set source_dir=source
set dest_dir=transl/

:: Iterate through all .ftx files in the source directory
for %%f in (%source_dir%\*.ftx) do (
    echo Translating %%~nxf...
    kcdict %%f %dest_dir%
)
move /y cnfg.kl "%source_dir%" >nul
del /q  cnfg.vr 
del /q macnfgeg.tx 
move /y dldc.kl "%source_dir%" >nul
del /q  dldc.vr
del /q madldceg.tx
move /y mcdc.kl "%source_dir%" >nul
del /q  mcdc.vr
del /q mamcdceg.tx
move /y mmdc.kl "%source_dir%" >nul
del /q  mmdc.vr
del /q mammdceg.tx
move /y midc.kl "%source_dir%" >nul
del /q  midc.vr
del /q mamidceg.tx
:: Compile specific .kl files
:: Add each file name below in the format: filename.kl
::for %%f in (%source_dir%\*.kl) do (
::    echo Checking %%~nxf...
::    :: Exclude files ending with _h.kl
::    echo %%~nxf | findstr /r /c:"_h\.kl$" >nul
::    if errorlevel 1 (
::        echo Compiling %%~nxf...
::        ktrans "%%f" "%dest_dir%"
::    ) else (
::        echo Skipping header file %%~nxf.
::    )
::)
:: Loop through all .kl files in the source directory
for %%f in ("%source_dir%\*.kl") do (
    set "filename=%%~nxf"
    call :check_and_compile
)
for %%f in (*.pc) do (
    echo deleting %%~nxf...
    del /q %%f 
)
echo All specified files have been compiled.
goto :eof

:transl_dict
if exist "%source_dir%\%1" (
    echo Translating dict %1...
    kcdict "%source_dir%\%1" "%dest_dir%"
) else (
    echo File %1 does not exist in %source_dir%.
)
goto :eof
:compile_file
if exist "%source_dir%\%1" (
    echo Compiling %1...
    ktrans "%source_dir%\%1" "%dest_dir%"
) else (
    echo File %1 does not exist in %source_dir%.
)
goto :eof
:check_and_compile
:: Check if the filename contains "_h.kl"
echo %filename% | find "_h.kl" >nul
if errorlevel 1 (
    echo Compiling: %filename%
    ktrans "%source_dir%\%filename%" "%dest_dir%"
) else (
    echo Skipping header file: %filename%
)
goto :eof