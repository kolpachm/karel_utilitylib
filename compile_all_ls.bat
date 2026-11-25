@echo off
setlocal

if not exist output mkdir output

for %%f in (src/*.ls) do (
    echo Compiling %%~nxf ...
    maketp src/%%~nxf output/%%~nf.tp
)

echo Done.
endlocal
