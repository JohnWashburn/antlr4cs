@ECHO on
SETLOCAL ENABLEDELAYEDEXPANSION

CALL :TestScript >.\Publish.Antlr4.log 2>&1

:TestScript

:display Now
echo %DATE% %TIME%

RMDIR /S /Q ".\Nuget"
mkdir ".\Nuget"

NuGet Update -self
NuGet Pack Antlr4.nuspec /OutputDirectory "./Nuget"
copy ".\Nuget\Antlr4.*.nupkg" "\\uva\nuget\*" /y

:: the single exit point for this script
:ExecutionComplete
EXIT /b