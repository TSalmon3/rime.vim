# build-query.ps1 - 编译 rime-query (Windows)
# 用法: build-query.ps1 <编译器> <编译参数> <include路径> <lib路径> <输出目录> [rime.dll路径]
param(
    [string]$Compiler,
    [string]$Flags,
    [string]$IncludeDir,
    [string]$LibDir,
    [string]$OutputDir,
    [string]$DllPath = ''
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$SrcFile = Join-Path $ProjectDir "cpp\rime-query.cc"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

$ArgList = @($Flags.Split(' '))
$ArgList += "/I$ProjectDir\cpp\3rd"
$ArgList += "/I$IncludeDir"
$ArgList += $SrcFile
$ArgList += "/link"
$ArgList += "/LIBPATH:$LibDir"
$ArgList += "rime.lib"
$ArgList += "ws2_32.lib"
$ArgList += "/OUT:$OutputDir\rime-query.exe"

& $Compiler @ArgList
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# 编译成功后，把 rime.dll 拷贝到 exe 同一目录（未配置则跳过）
if ($DllPath -ne '' -and (Test-Path $DllPath)) {
    Copy-Item -Force $DllPath (Join-Path $OutputDir 'rime.dll')
}
