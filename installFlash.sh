#!/usr/bin/env bash

## HEADER
# Script Title: Adobe Flash Downloader
# Author: Conor Schutzman <conor@mac.com>
# Inspired by "Install Latest Adobe Flash Player" by RTrouton

## DEFINITIONS
SoftwareTitle=Flash
SectionTitle=Flash
LogFile="/Library/Logs/$SoftwareTitle.log"
TimeStamp=$(date "+%Y %b %d %T")
ConsoleUser=$(stat -f %Su '/dev/console')
FilerURL="http://fpdownload.macromedia.com/get/flashplayer/current/licensing/mac"
SourceDMG="install_flash_player_14_osx_pkg.dmg"
WebVersion=14.0.0.125
BackupLocation="/Library/Backup"
FlashLocation='/Library/Internet Plug-Ins/Flash Player.plugin'
InstallDMG="flash.dmg"

## LOGGING
writeLog(){ echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$ConsoleUser] [$ScriptTitle] [$SectionTitle] $1" >> "$LogFile"; }
[[ -e "$(dirname "$LogFile")" ]] || mkdir -p -m 775 "$(dirname "$LogFile")"
[[ "$(stat -f%z "$LogFile")" -ge 1000000 ]] && rm -rf "$LogFile"

## BODY
SectionTitle=Verification
[[ -e "$FlashLocation" ]] || exit 0
CurrentVersion=$(defaults read "$FlashLocation/Contents/Info.plist" CFBundleVersion)
[[ "$(echo "$WebVersion" | awk -F'.' '{print $1}')" -le "$(echo "$CurrentVersion" | awk -F'.' '{print $1}')" ]] && exit 0
if [[ -e "$FlashLocation" ]]; then
	writeLog "Installed Flash version: $CurrentVersion"
else
	writeLog "Existing installation of Flash not found"
fi
writeLog "Current available version: $WebVersion"
SectionTitle=Download
[[ -d "$BackupLocation" ]] || mkdir -p -m 775 "$BackupLocation"
FilerConnection=$(curl -L -s -o "/dev/null" --silent --head --write-out '%{http_code}' "$FilerURL/$SourceDMG" --location-trusted -X GET)
writeLog "Connection status: $FilerConnection"
if [[ "$FilerConnection" -eq 200 ]]; then
	curl -L "$FilerURL/$SourceDMG" -o "$BackupLocation/$InstallDMG" --silent --location-trusted >> "$LogFile"
else
	writeLog "Connection error"
	echo "Unable to connect to Adobe servers"
	exit 1
fi
SectionTitle=Mount
MountPoint=$(/usr/bin/mktemp -d /tmp/flashplayer.XXXX)
if [[ -e "$BackupLocation/$InstallDMG" ]]; then
	hdiutil attach "$BackupLocation/$InstallDMG" -mountpoint "$MountPoint" -nobrowse -noverify -noautoopen
	writeLog "Mounted DMG $BackupLocation/$InstallDMG at $MountPoint"
else
	writeLog "Unable to find DMG at $BackupLocation"
	ls -la "$BackupLocation" >> "$LogFile"
	echo "Install DMG download not successful"
	exit 1
fi
SectionTitle=Install
if [[ -e "$(find "$MountPoint" -maxdepth 1 \( -iname \*\.pkg -o -iname \*\.mpkg \))" ]]; then
	writeLog "Executing package at: $FlashInstaller"
	installer -dumplog -pkg "$FlashInstaller" -target / >> "$LogFile"
else
	writeLog "Installer package not found"
	echo "Installer package not found on DMG"
	exit 1
fi
SectionTitle=CleanUp
writeLog "Unmounting install DMG"
hdiutil detach "$MountPoint" >> "$LogFile"
[[ -e "$BackupLocation/$InstallDMG" ]] && rm -rfv "$BackupLocation/$InstallDMG" >> "$LogFile"
SectionTitle=Confirmation

writeLog "Installed Flash version: $CurrentVersion"
if [[ "$(echo "$WebVersion" | awk -F'.' '{print $1}')" = "$(defaults read "$FlashLocation/Contents/Info.plist" CFBundleVersion | awk -F'.' '{print $1}')" ]]; then
	SectionTitle=Complete
	writeLog "Update successful"
else
	writeLog "Update failed"
	echo "Flash not updated"
	exit 1
fi

## FOOTER
exit 0