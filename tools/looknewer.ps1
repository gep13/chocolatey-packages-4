$ErrorActionPreference = 'Continue';

$source = Join-Path $PSScriptRoot "Check/list.txt"
Install-PackageProvider -name winget -Force
. $PSScriptRoot\..\scripts\New-Githubissue.ps1
Install-Module psgithubsearch
Import-Module psgithubsearch

if(!(Test-Path Env:github_api_key)) {
    $Env:github_api_key   = $Github_personal_token          #Github personal access token
}
[string]$Owner = "tunisiano187"
[string]$Repository = "Chocolatey-packages"
$UserToken = $env:github_api_key
$Headers = @{
    Authorization='token '+$UserToken
}

if((Test-Path $source) -and (!(Find-GitHubIssue -Type issue -Repo "$Owner/$Repository" -Labels 'ToCreateManualy' -State open))) {
    $search = (Get-Content $source | Select-Object -First 1).split(' ')[0]
    if(!(Test-Path "$($PSScriptRoot)/../automatic/$search")) {
        if($winout = ($(Find-Package $search).Version)) {
            "|$search|" | Add-Content "$($PSScriptRoot)/Check/Todo.md"
            Write-Host "$search v$($winout) available"
            [string]$Label = "ToCreateFrom"
            [string]$Title = "([$search](https://chocolatey.org/packages/$search)) Needs update"
            [string]$Description = "($search) Outdated and needs to be updated"
            if(!(Find-GitHubIssue -Type issue -Repo "$Owner/$Repository" -Keywords "$Title" -Labels 'ToCreateManualy' -State open)) {
                New-GithubIssue -Title $Title -Description $Description -Label $Label -owner $Owner -Repository $Repository -Headers $Headers
            }
        } else {
            Write-host "$search not available on winget"
            "|$search|" | Add-Content "$($PSScriptRoot)/Check/Todo.md"
            Get-Content $source | Select-Object -Skip 1 | set-content "$source-temp"
            Move-Item "$source-temp" $source -Force
            [string]$Label = "ToCreateManualy"
            [string]$Title = "($search) Needs update"
            [string]$Description = "([$search](https://chocolatey.org/packages/$search)) Outdated and needs to be updated"
            if(!(Find-GitHubIssue -Type issue -Repo "$Owner/$Repository" -Keywords "$Title" -Labels 'ToCreateManualy' -State open)) {
                New-GithubIssue -Title $Title -Description $Description -Label $Label -owner $Owner -Repository $Repository -Headers $Headers
            }
        }
    } else {
        Write-host "$search already maintained here"
        Get-Content $source | Select-Object -Skip 1 | set-content "$source-temp"
        Move-Item "$source-temp" $source -Force
    }
    git add -u :/tools/Check/
    git commit -m "Package check $search"
    git push origin master
}