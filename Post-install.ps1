# Vérification des privilèges administrateurs
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

Clear-Host

# Définir l'URL et le chemin d'installation
$SevenZipURL = "https://www.7-zip.org/a/7z2301-x64.exe"  # Mettez Ã  jour l'URL si une nouvelle version est disponible
$InstallerPath = "$env:TEMP\7zsetup.exe"

# Télécharger l'installateur de 7-Zip
Write-Host "Téléchargement de l'installateur de 7-Zip..."
Invoke-WebRequest -Uri $SevenZipURL -OutFile $InstallerPath -UseBasicParsing

# Installer 7-Zip en mode silencieux
Write-Host "Installation de 7-Zip en mode silencieux..."
Start-Process -FilePath $InstallerPath -ArgumentList "/S" -Wait

# Supprimer le fichier d'installation
Write-Host "Nettoyage..."
Remove-Item -Path $InstallerPath -Force
Clear-Host

# Vérification de la connexion a internet
Write-Host "MERCI DE VÉRIFIER QUE VOUS ÊTES CONNECTÉ À INTERNET. SI CE N'EST PAS LE CAS, INSTALLEZ VOS PILOTES ETHERNET OU WI-FI" -ForegroundColor Green
Write-Host "SI TOUT EST BON, MERCI D'APPUYER SUR ENTRER POUR LA SUITE DE L'INSTALLATION"
Read-Host

# Installation du module Windows Update & Mise a jour système
Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
Install-Module -Name PSWindowsUpdate -Force
Clear-Host
Get-WindowsUpdate -NotCategory "Drivers" -NotTitle "nvidia" -AcceptAll -Install -AutoReboot
Clear-Host
Write-Host "MERCI D'APPUYER SUR ENTRER POUR INSTALLER VOS PILOTES NVIDIA" 
Read-Host
Clear-Host

# Vérification de l'installation de 7-Zip
$sevenZipPath = "C:\Program Files\7-Zip\7z.exe"
if (-Not (Test-Path $sevenZipPath)) {
    Write-Host "7-Zip n'est pas installÃ© ou introuvable. Installez-le avant de continuer." -ForegroundColor Red
    exit
}

# Séléction du driver NVIDIA
Write-Host "Selectionnez votre driver NVIDIA :

"
Write-Host "[1] 472.12 (1000/2000)
"

Write-Host "[2] 551.61 (3000/4000)
"

Write-Host "[3] 566.14 (4080/4090)
"

$NVIDIADRIVER = Read-Host "Selectionnez votre driver"
Clear-Host

# Téléchargement du driver avec Curl.exe
$destinationFolder = "$env:TEMP"
$url = switch ($NVIDIADRIVER) {
    "1" { "https://us.download.nvidia.com/Windows/472.12/472.12-desktop-win10-win11-64bit-international-whql.exe" }
    "2" { "https://us.download.nvidia.com/Windows/551.61/551.61-desktop-win10-win11-64bit-international-dch-whql.exe" }
    "3" { "https://us.download.nvidia.com/Windows/566.03/566.03-desktop-win10-win11-64bit-international-dch-whql.exe" }
    default { Write-Host "Choix invalide." -ForegroundColor Red; exit }
}

$tempFile = Join-Path $env:TEMP "$NVIDIADRIVER.zip"
Write-Host "TÃ©lÃ©chargement de $url..."
curl.exe "$url" -# -o  "$tempFile" 
Write-Host "Téléchargement terminé : $tempFile"



# Extraction du driver
$destinationPath = Join-Path $env:TEMP $NVIDIADRIVER
Write-Host "Extraction du driver NVIDIA en cours..."
& $sevenZipPath x -y -o"$destinationPath" "$tempFile" > $null 2>&1
Write-Host "Extraction terminée : $destinationPath"

# Nettoyage du package NVIDIA
Write-Host "Nettoyage du driver NVIDIA..."
$keepItems = @("Display.Driver", "GFExperience", "NVI2", "EULA.txt", "ListDevices.txt", "setup.cfg", "setup.exe")
Get-ChildItem -Path $destinationPath -Force | ForEach-Object {
    if (-Not ($keepItems -contains $_.Name)) {
        Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "Nettoyage terminé."

# Lancement de l'installation
Write-Host "Lancement de l'installation NVIDIA..."
Start-Process -FilePath "$destinationPath\setup.exe" -NoNewWindow


