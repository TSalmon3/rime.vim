# build-query.ps1 - 编译 rime-query (Windows, clang++)
# 用法: build-query.ps1 -Compiler <编译器> -Flags <编译参数> -IncludeDir <include路径> -LibDir <lib路径> -OutputDir <输出目录> [-DllPath <rime.dll路径>]
param(
    [string]$Compiler,
    [string]$Flags,
    [string]$IncludeDir,
    [string]$LibDir,
    [string]$OutputDir,
    [string]$DllPath = ''
)

$ErrorActionPreference = "Stop"

# 统一路径分隔符为反斜杠（Vim 传入的路径使用正斜杠）
$IncludeDir = $IncludeDir.Replace('/', '\')
$LibDir = $LibDir.Replace('/', '\')
$OutputDir = $OutputDir.Replace('/', '\')
$DllPath = $DllPath.Replace('/', '\')

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$SrcFile = Join-Path $ProjectDir "cpp\rime-query.cc"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

$ArgList = @($Flags.Split(' '))
$ArgList += "-I$ProjectDir\cpp\3rd"
$ArgList += "-I$IncludeDir"
$ArgList += $SrcFile
$ArgList += "-L$LibDir"
$ArgList += "-lrime"
$ArgList += "-lws2_32"
$ArgList += "-o"
$ArgList += "$OutputDir\rime-query.exe"

& $Compiler @ArgList
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# 编译成功后，把 rime.dll 拷贝到 exe 同一目录（未配置则跳过）
if ($DllPath -ne '' -and (Test-Path $DllPath)) {
    Copy-Item -Force $DllPath (Join-Path $OutputDir 'rime.dll')
}
