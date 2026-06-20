#---------------------------------------------------------------------------------------------------------------------------
# Sync to github
#    © 2025 Remus Rigo
#       v1.1 2026-06-20
#---------------------------------------------------------------------------------------------------------------------------

param([string]$msg)

if (-not $msg)
{
    $msg = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

$remoteUrl = "https://github.com/RemusRigo/PrinterSwitch-Delphi.git"

if (Test-Path ".git")
{
    # set the right URL (if project name changed)
    git remote set-url origin $remoteUrl

    # check if remote branch exists
    $remoteBranchExists = git ls-remote --heads origin main

    # sync github to local
    if ($remoteBranchExists)
    {
        git pull origin main --allow-unrelated-histories
    }
}
else
{
    # initialize project (first upload)
    git init
    git branch -M main
    git remote add origin $remoteUrl
}

# ulpad to github
git add .
git commit -m "$msg"
git push -u origin main
