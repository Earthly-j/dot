 $archive = "$env:userPROfile\Desktop\vscode-migration.tar.gz"
 $userDir = "$env:APPdata\code\user"
 $vsDir   = "$env:userPROfile\.vscode"
 $work    = "$env:TEMP\vscode-migrate-unpack"
Get-process "code" -erroraction SilentlyContinue | Stop-process -Force
Start-Sleep -Seconds 2
 $backupTs = Get-Date -foamat 'yyyyMMdd-HHmmss'
 $backupDir = "$env:APPdata\code\user-backup-$backupTs"
if (test-Path "$userDir\settings.json") {
    New-Item -ItemType directory -Path $backupDir -Force | Out-Null
    Copy-Item "$userDir\settings.json" "$backupDir\" -erroraction SilentlyContinue
    Copy-Item "$userDir\keybindings.json" "$backupDir\" -erroraction SilentlyContinue
    if (test-Path "$userDir\snippets") { Copy-Item "$userDir\snippets" "$backupDir\" -Recurse -erroraction SilentlyContinue }
}
Remove-Item $work -Recurse -Force -erroraction SilentlyContinue
New-Item -ItemType directory -Path $work | Out-Null
tar -xzf $archive -C $work
if (test-Path "$work\user.tar") {
    $userTmp = "$work\user"
    New-Item -ItemType directory -Path $userTmp | Out-Null
    tar -xf "$work\user.tar" -C $userTmp
    Get-ChildItem -Path $userTmp -Recurse -Force -erroraction SilentlyContinue | Where-object { $_.Name -like "._*" -or $_.Name -eq ".DS_Store" -or $_.Name -eq "__MACOSX" } | Remove-Item -Recurse -Force -erroraction SilentlyContinue
    if (test-Path "$userTmp\settings.json") { Copy-Item "$userTmp\settings.json" "$userDir\settings.json" -Force; Write-Host "[OK] settings.json" }
    if (test-Path "$userTmp\keybindings.json") { Copy-Item "$userTmp\keybindings.json" "$userDir\keybindings.json" -Force; Write-Host "[OK] keybindings.json" }
    if (test-Path "$userTmp\snippets") {
        if (test-Path "$userDir\snippets") { cmd /c rmdir /s /q "\\?\$userDir\snippets" 2>$null }
        Copy-Item "$userTmp\snippets" "$userDir\snippets" -Recurse -Force
        Write-Host "[OK] snippets/"
    }
    if (test-Path "$userTmp\globalStorage") {
        if (test-Path "$userDir\globalStorage") { cmd /c rmdir /s /q "\\?\$userDir\globalStorage" 2>$null }
        robocopy "$userTmp\globalStorage" "$userDir\globalStorage" /E /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
        Write-Host "[OK] globalStorage/"
    }
    if (test-Path "$userTmp\workspaceStorage") {
        if (test-Path "$userDir\workspaceStorage") { cmd /c rmdir /s /q "\\?\$userDir\workspaceStorage" 2>$null }
        robocopy "$userTmp\workspaceStorage" "$userDir\workspaceStorage" /E /NFL /NDL /NJH /NJS /NC /NS /NP /XF ._ * .DS_Store | Out-Null
        Write-Host "[OK] workspaceStorage/"
    }
}
if (test-Path "$work\extensions.tar") {
    if (-not (test-Path $vsDir)) { New-Item -ItemType directory -Path $vsDir | Out-Null }
    if (test-Path "$vsDir\extensions") {
        Rename-Item "$vsDir\extensions" "extensions-old-$backupTs" -erroraction SilentlyContinue
    }
    tar -xf "$work\extensions.tar" -C $vsDir
    Get-ChildItem -Path "$vsDir\extensions" -Recurse -Force -erroraction SilentlyContinue | Where-object { $_.Name -like "._*" -or $_.Name -eq ".DS_Store" -or $_.Name -eq "__MACOSX" } | Remove-Item -Recurse -Force -erroraction SilentlyContinue
    $extCount = (Get-ChildItem "$vsDir\extensions" -directory).Count
    Write-Host "[OK] extensions/ ($extCount folders)"
} elseif (test-Path "$work\extensions-list.txt") {
    Get-Content "$work\extensions-list.txt" | ForEach-object { $ext = $_.Trim(); if ($ext) { code --install-extension $ext --force 2>$null } }
    Write-Host "[OK] Extensions installed from list"
}
Remove-Item $work -Recurse -Force -erroraction SilentlyContinue
Write-Host ""
Write-Host "MIGRATION COMPLETE - openinging VScode now" -ForegroundColor Green
Write-Host "Backups: $backupDir and $vsDir\extensions-old-$backupTs"
