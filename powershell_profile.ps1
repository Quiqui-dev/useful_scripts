
# Check if the profile doesn't exist and then create it if not
if (!(Test-Path -Path $profile)) {
  New-Item -ItemType File -Path $profile -Force
}

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
    Write-Host ""
}

try {
    $gv = git --version
    Write-Host $gv -ForegroundColor "DarkGray"
    Write-Host ""
} catch {
    Write-Host "Git is not installed on this machine" -ForegroundColor "DarkGray"
    Write-Host ""
}

try {
    $pyv = python --version
    Write-Host $pyv -ForegroundColor "DarkGray"
    Write-Host ""
} catch {
    Write-Host "Python is not installed on this machine" -ForegroundColor "DarkGray"
    Write-Host ""
}

try {
    $nv = node --version
    Write-Host $nv -ForegroundColor "DarkGray"
    Write-Host ""
} catch {
    Write-Host "Node is not installed on this machine" -ForegroundColor "DarkGray"
    Write-Host ""
}

try {
    $dnv = dotnet --list-sdks
    Write-Host $dnv -ForegroundColor "DarkGray"
    Write-Host ""
} catch {
    Write-Host "dotnet is not installed on this machine" -ForegroundColor "DarkGray"
    Write-Host ""
}

# Set up functions to automate tasks

# Git Functions
function gitAdd {git add $args}
function gitCommit {git commit -m $args}
function gitStatus {git status}
function gitCheckout {git checkout $args}
function gitPull {git pull origin $args}
function gitPush {git push $args}
function gitPushSetUpstream {git push --set-upstream origin $args}
function gitPullRebase {git pull --rebase $args}
function lazyCommit {
    git add .
    git commit -m $args
    git push
}

# QOL Functions
function cdUp {Set-Location -Path .. -Force}
function vscodeOpen {code .}

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
function tfInit {terraform init $args}
function tfPlan {terraform plan $args}
function tfApply {terraform apply $args}
function tfShow {terraform show $args}
function tfTaint {terraform taint $args}
function tfValidate {terraform validate $args}
function tfFmt {terraform fmt $args}

#Configure Aliases using the below formula
#Set-Alias -Name "alias" -Value "function" -Force

Set-Alias -Name ga -Value gitAdd -Force
Set-Alias -Name gs -Value gitStatus -Force
Set-Alias -Name gcm -Value gitCommit -Force
Set-Alias -Name gpo -Value gitPull -Force
Set-Alias -Name gco -Value gitCheckout -Force
Set-Alias -Name gp -Value gitPush -Force
Set-Alias -Name gpsu -Value gitPushSetUpstream -Force
Set-Alias -Name gprb -Value gitPullRebase -Force
Set-Alias -Name gcl -Value lazyCommit -Force

Set-Alias -Name .. -Value cdUp -Force
Set-Alias -Name vsc -Value vscodeOpen -Force
Set-Alias -Name nsl -Value nslookup -Force

Set-Alias -Name tfi -Value tfInit -Force
Set-Alias -Name tfp -Value tfPlan -Force
Set-Alias -Name tfa -Value tfApply -Force
Set-Alias -Name tff -Value tfFmt -Force
Set-Alias -Name tfv -Value tfValidate -Force
Set-Alias -Name tft -Value tfTaint -Force
Set-Alias -Name tfsh -Value tfShow -Force

# We don't need these any more; they were just temporary variables to get to $isAdmin. 
# Delete them to prevent cluttering up the user profile. 
Remove-Variable identity
Remove-Variable principal