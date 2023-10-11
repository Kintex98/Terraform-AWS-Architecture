#############################################################################################
#
# You are free to copy and redistribute the material in any medium or format by Khiem Nguyen.
#
# Author      : Khiem Nguyen (Kintex98)
# Created     : October 10, 2023
# Description : Installs the latest version of Notepad++
# Filename    : Update-Notepad++.ps1
#
#############################################################################################

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$NotepadWebPage = Invoke-WebRequest -Uri "https://notepad-plus-plus.org" -UseBasicParsing

If ($null -ne $NotepadWebPage) {
  $NotepadDownloadPath = $NotepadWebPage.Links | Where-Object { $_.outerHTML -like '*Current Version*' } | Select-Object -ExpandProperty href
  # Uses the URL found in "Current Version" to grab the download page. From there the .exe and sha256 are fetched
  $NotepadDownloadPage = Invoke-WebRequest -Uri "https://notepad-plus-plus.org$NotepadDownloadPath" -UseBasicParsing
  $NotepadExeUrl = $NotepadDownloadPage.Links | Where-Object { $_.outerHTML -like '*npp.*.Installer.x64.exe"*' } | Select-Object -ExpandProperty href -Unique
  $NotepadSourceShaUrl = $NotepadDownloadPage.Links | Where-Object { $_.outerHTML -like '*npp.*.checksums.sha256"*' } | Select-Object -ExpandProperty href -Unique
  $NotepadSourceSha = "./$(Split-Path -Path $NotepadSourceShaUrl -Leaf)"
  Invoke-WebRequest -Uri $NotepadSourceShaUrl -OutFile $NotepadSourceSha
}
Else {
  Write-Output 'Could not resolve the notepad web page, skipping the installation.'
  Remove-Item $NotepadSourceSha
  Exit 1
}

Write-Output 'Installing the executable for the latest Notepad++ installation...'
$NotepadInstaller = "./$(Split-Path -Path $NotepadExeUrl -Leaf)"
Invoke-WebRequest -Uri $NotepadExeUrl -OutFile $NotepadInstaller
# If the SHA256 of the executable is not a string within the $NotepadSourceSha file, then the executable is not valid
If (Get-Content $NotepadSourceSha | Select-String (Get-FileHash $NotepadInstaller -Algorithm SHA256).Hash) {
  Write-Output "The SHA256 of the latest Notepad++ executable was found in the $NotepadSourceSha file, continuing with installation..."
  Write-Output "Executing Notepad++ installer..."
  & "./$NotepadInstaller" @("/S")
}
Else {
  Write-Output "The Notepad++ installation has failed due to an invalid SHA256."
  Remove-Item $NotepadSourceSha
  Remove-Item $NotepadInstaller
  Exit 1
}
