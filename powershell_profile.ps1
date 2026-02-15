
# Check if the profile doesn't exist and then create it if not
if (!(Test-Path -Path $profile)) {
  New-Item -ItemType File -Path $profile -Force
}

if (!(Test-Path -Path "${env:ProgramFiles}\devtools")) {

  Write-Host "Did not find a devtools directory, creating one"
  New-Item -ItemType Directory -Path "${env:ProgramFiles}\devtools" -Force

  Write-Host "Setting devtools directory on PATH for Machine"
  $p = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
  $p = "$devtools;$p"
  [System.Environment]::SetEnvironmentVariable("PATH", "$p", "Machine")
}

# Set Environment Variables here:
if (Get-Module -ListAvailable -Name Az.Account) {
    $ENV:ARM_SUBSCRIPTION_ID = (Get-AzContext).Subscription.Id
} else {
    Write-Warning "Azure Account Module not installed, will not set ARM_SUBSCRIPTION_ID"
}

# Figure out how to do the AWS equivalent 

# Find out if the current user identity is elevated (has admin rights)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# If so and the current host is a command line, then change to red color 
# as warning to user that they are operating in an elevated context
if (($host.Name -match "ConsoleHost") -and ($isAdmin))
{
     $host.UI.RawUI.BackgroundColor = "DarkRed"
     $host.PrivateData.ErrorBackgroundColor = "White"
     $host.PrivateData.ErrorForegroundColor = "DarkRed"
     Clear-Host
}

# Set your default location to open for the PS Shell
Set-Location ""

# Get some basic info for you
Write-Host ""
Write-Host "Loaded Profile From:" $profile -ForegroundColor "DarkGray"
Write-Host ""

# quick stuff to see which languages are installed on this machine 
try {
    $tfv = terraform --version
    Write-Host $tfv -ForegroundColor "DarkGray"
} catch {
    Write-Host "Terraform is not installed on this machine" -ForegroundColor "DarkGray"
    Write-Host "run 'intf' to install the latest terraform version" -ForegroundColor "DarkGray"
    Write-Host ""
}

try {
    $gv = git --version
    Write-Host $gv -ForegroundColor "DarkGray"
    Write-Host ""
} catch {
    Write-Host "Git is not installed on this machine" -ForegroundColor "DarkGray"
    Write-Host "run 'ingit' to install the latest git version" -ForegroundColor "DarkGray"
    Write-Host ""
}

try {
    $gover = go --version
    Write-Host $gover -ForegroundColor "DarkGray"
    Write-Host ""
} catch {
    Write-Host "go is not installed on this machine" -ForegroundColor "DarkGray"
    Write-Host "run 'ingo' to install the latest Go version" -ForegroundColor "DarkGray"
    Write-Host ""
}

try {
    $dockerver = docker version
    Write-Host $dockerver -ForegroundColor "DarkGray"
    Write-Host ""
} catch {
    Write-Host "docker is not installed on this machine" -ForegroundColor "DarkGray"
    Write-Host "run 'indkr' to install the latest docker version" -ForegroundColor "DarkGray"
    Write-Host ""
}

try {
    $pyv = python --version
    Write-Host $pyv -ForegroundColor "DarkGray"
    Write-Host ""
} catch {
    Write-Host "Python is not installed on this machine" -ForegroundColor "DarkGray"
    Write-Host "run 'inpy' to install the latest Python version" -ForegroundColor "DarkGray"
    Write-Host ""
}

try {
    $nv = node --version
    Write-Host $nv -ForegroundColor "DarkGray"
    Write-Host ""
} catch {
    Write-Host "Node is not installed on this machine" -ForegroundColor "DarkGray"
    Write-Host "run 'innd' to install the latest node-lts version" -ForegroundColor "DarkGray"
    Write-Host ""
}

try {
    $dnv = dotnet --list-sdks
    Write-Host $dnv -ForegroundColor "DarkGray"
    Write-Host ""
} catch {
    Write-Host "dotnet is not installed on this machine" -ForegroundColor "DarkGray"
    Write-Host "run 'indn' to install the latest dotnet version" -ForegroundColor "DarkGray"
    Write-Host ""
}

# Set up functions to automate tasks

# Install Languages / Tools
function indn {}
function innd {}
function inpy {
    $TmpDir = "${env:SystemDrive}\Temp"
    if (!(Test-Path $TmpDir)) { New-Item -ItemType Directory $TmpDir -Force }
    $PyReleases = Invoke-RestMethod 'https://github.com/python/cpython/releases.atom'
    # Drop the "v" and filter out versions with letters in it, cast to a version, sort descending and select the first result
    $PyLatestVersion = ($PyReleases.title) -replace "^v" -notmatch "[a-z]" | Sort-Object { [version] $_ } -Descending | Select-Object -First 1
    $PyLatestBaseUrl = "https://www.python.org/ftp/python/${PyLatestVersion}"
    $PyUrl = "${PyLatestBaseUrl}/python-${PyLatestVersion}-amd64.exe"
    $PyPkg = $PyUrl | Split-Path -Leaf
    # Also could use: $PyPkg = "python-${PyLatestVersion}-amd64.exe"
    $PyVerDir = ($PyPkg -replace "\.exe" -replace "-amd64" -replace "-").Split(".")
    $PyVerDir = $PyVerDir[0] + $PyVerDir[-2]
    $PyVerDir = $PyVerDir.Substring(0, 1).ToUpper() + $PyVerDir.Substring(1).ToLower()
    $PyCmd = "${env:ProgramFiles}\${PyVerDir}\python.exe"
    Invoke-WebRequest -UseBasicParsing -Uri $PyUrl -OutFile "${TmpDir}\${PyPkg}"
    Start-Process "${TmpDir}\${PyPkg}" -ArgumentList "/passive", "InstallAllUsers=1", "PrependPath=1", "Include_test=0" -Wait -NoNewWindow
}

function install-tfsummarize {

    $devtools = "${env:ProgramFiles}\devtools"
    $url = "https://github.com/dineshba/tf-summarize/releases/download/v0.3.15/tf-summarize_windows_amd64.zip"
    $downloadDir = $env:TEMP

    Write-Host "Downloading $url"
    $zip = "$downloadDir\tf-sum.zip"
    if (!(Test-Path "$zip")) {
        $downloader = new-object System.Net.WebClient
        $downloader.DownloadFile($url, $zip)
    }

    Write-Host "Extracting $zip to $devtools"
    if (Test-Path "$downloadDir\tf-summarize.exe") {
        Remove-Item -Force -Recurse -Path "$downloadDir\tf-summarize.exe"
        Remove-Item -Force -Recurse -Path "$downloadDir\LICENSE"
        Remove-Item -Force -Recurse -Path "$downloadDir\README.md"
    }
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$zip", "$downloadDir")

    if (Test-Path "$downloadDir\tf-summarize.exe") {
        Move-Item "$downloadDir\tf-summarize.exe" $devtools -Force
        Remove-Item -Force -Recurse -Path "$downloadDir\LICENSE"
        Remove-Item -Force -Recurse -Path "$downloadDir\README.md"
    }
}

function ingo {

    Param(
        [String]$version
    )

    if ($version -eq "" ) {
        Write-Error "Error: -version is required"
        Write-Error "Enter the version of golang you would like to install"
        exit 1
    }

    $downloadDir = $env:TEMP
    $packageName = 'golang'
    $url32 = 'https://storage.googleapis.com/golang/go' + $version + '.windows-386.zip'
    $url64 = 'https://storage.googleapis.com/golang/go' + $version + '.windows-amd64.zip'
    $goroot = "C:\go$version"

    # Determine type of system
    if ($ENV:PROCESSOR_ARCHITECTURE -eq "AMD64") {
        $url = $url64
    } else {
        $url = $url32
    }

    if (Test-Path "$goroot\bin\go") {
    Write-Host "Go is installed to $goroot"
    exit
    }

    Write-Host "Downloading $url"
    $zip = "$downloadDir\golang-$version.zip"
    if (!(Test-Path "$zip")) {
        $downloader = new-object System.Net.WebClient
        $downloader.DownloadFile($url, $zip)
    }

    Write-Host "Extracting $zip to $goroot"
    if (Test-Path "$downloadDir\go") {
        Remove-Item -Force -Recurse -Path "$downloadDir\go"
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$zip", $downloadDir)
    Move-Item "$downloadDir\go" $goroot

    Write-Host "Setting GOROOT and PATH for Machine"
    [System.Environment]::SetEnvironmentVariable("GOROOT", "$goroot", "Machine")
    $p = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $p = "$goroot\bin;$p"
    [System.Environment]::SetEnvironmentVariable("PATH", "$p", "Machine")

}

function indkr {}
function intf {}
function ingit {}


# Git Functions
function gitAdd             {git add $args}
function gitCommit          {git commit -m $args}
function gitStatus          {git status $args}
function gitCheckout        {git checkout $args}
function gitPull            {git pull origin $args}
function gitPush            {git push $args}
function gitPushSetUpstream {git push --set-upstream origin $args}
function gitPullRebase      {git pull --rebase $args}
function lazyCommit {
    git add .
    git commit -m $args
    git push
}

# QOL Functions
function cdUp       {Set-Location ..}
function vscodeOpen {code $args}

# Compute file hashes - useful for checking successful downloads 
function md5    { Get-FileHash -Algorithm MD5 $args }
function sha1   { Get-FileHash -Algorithm SHA1 $args }
function sha256 { Get-FileHash -Algorithm SHA256 $args }

# Quick shortcut to start notepad
function n      { notepad $args }

# Drive shortcuts
function HKLM:  { Set-Location HKLM: }
function HKCU:  { Set-Location HKCU: }
function Env:   { Set-Location Env: }

# Terraform shortcuts
function tfInit     {terraform init $args}
function tfPlan     {terraform plan $args}
function tfApply    {terraform apply $args}
function tfShow     {terraform show $args}
function tfTaint    {terraform taint $args}
function tfValidate {terraform validate $args}
function tfFmt      {terraform fmt $args}
function tfSum      {tf-summarize.exe $args}

# Docker shortcuts
function DockerAlias        {docker $args}
function DockerComposeAlias {docker compose $args}

# Dotnet shortcuts 
function DotnetBuild {dotnet build $args}
function DotnetClean {dotnet clean $args}
function DotnetFmt   {dotnet format $args}
function DotnetPack  {dotnet pack $args}
function DotnetAlais {dotnet $args}
function DotnetRun   {dotnet run $args}

#Configure Aliases using the below formula
#Set-Alias -Name "alias" -Value "function" -Force

Set-Alias -Name ga   -Value gitAdd             -Force
Set-Alias -Name gs   -Value gitStatus          -Force
Set-Alias -Name gcm  -Value gitCommit          -Force
Set-Alias -Name gpo  -Value gitPull            -Force
Set-Alias -Name gp   -Value gitPush            -Force
Set-Alias -Name gpsu -Value gitPushSetUpstream -Force
Set-Alias -Name gprb -Value gitPullRebase      -Force
Set-Alias -Name gcl  -Value lazyCommit         -Force

Set-Alias -Name ..  -Value cdUp       -Force
Set-Alias -Name vsc -Value vscodeOpen -Force
Set-Alias -Name nsl -Value nslookup   -Force

Set-Alias -Name tfi   -Value tfInit     -Force
Set-Alias -Name tfp   -Value tfPlan     -Force
Set-Alias -Name tfa   -Value tfApply    -Force
Set-Alias -Name tff   -Value tfFmt      -Force
Set-Alias -Name tfv   -Value tfValidate -Force
Set-Alias -Name tft   -Value tfTaint    -Force
Set-Alias -Name tfsum -Value tfSum      -Force
Set-Alias -Name tfsh  -Value tfShow     -Force

Set-Alias -Name dkr  -Value DockerAlias        -Force
Set-Alias -Name dkrc -Value DockerComposeAlias -Force

Set-Alias -Name dn  -Value DotnetAlias -Force
Set-Alias -Name dnb -Value DotnetBuild -Force
Set-Alias -Name dnf -Value DotnetFmt   -Force
Set-Alias -Name dnp -Value DotnetPack  -Force
Set-Alias -Name dnr -Value DotnetRun   -Force
Set-Alias -Name dnc -Value DotnetClean -Force


# We don't need these any more; they were just temporary variables to get to $isAdmin. 
# Delete them to prevent cluttering up the user profile. 
Remove-Variable identity
Remove-Variable principal