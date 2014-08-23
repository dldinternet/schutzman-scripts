#!/usr/bin/env bash

## HEADER
# Package Title: Clam Shucker 1.0
# Author: Conor Schutzman <conor@mac.com>

## DEFINITIONS
SoftwareTitle=Clam
LogFile="/Library/Logs/$SoftwareTitle.log"
TimeStamp=$(date "+%Y %b %d %T")
ConsoleUser=$(stat -f %Su "/dev/console")

## ARRAYS
ClamAgents=(
	'/Library/LaunchAgents/uk.co.markallan.clamxav.clamscan.plist'
	'/Library/LaunchAgents/uk.co.markallan.clamxav.freshclam.plist'
	)

## LOGGING
writeLog(){ echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$ConsoleUser] [$ScriptTitle] [Uninstall] $1" >> "$LogFile"; }
[[ -e "$(dirname "$LogFile")" ]] || mkdir -p -m 775 "$(dirname "$LogFile")"
[[ "$(stat -f%z "$LogFile")" -ge 1000000 ]] && rm -rf "$LogFile"

## BODY
[[ "$(system_profiler SPApplicationsDataType | grep -c "ClamXav")" < 1 ]] && exit 0
writeLog "Current Clam Xav version: $(system_profiler SPApplicationsDataType | grep "ClamXav" | grep "Get Info" | awk -F" " '{print $5}')"
osascript -e 'tell application "ClamXav" to quit'
# CronTab scheduled scans
crontab -l | grep -v \"no crontab for\" | grep -v \"freshclam\" | grep -v \"clamscan\" > "/tmp/crontmp"
[[ -e "/tmp/crontmp" ]] && crontab "/tmp/crontmp"
# LaunchAgents
writeLog "LaunchAgents removed:"
for EachAgent in "${ClamAgents[@]}"; do
	if [[ -e "$EachAgent" ]]; then
		launchctl unload -w "$EachAgent"
		rm -rfv "$EachAgent" >> "$LogFile"
	fi
	if [[ -e "/Users/$ConsoleUser/$EachAgent" ]]; then
		sudo -u "$ConsoleUser" launchctl unload -w "$EachAgent"
		rm -rfv "/Users/$ConsoleUser/$EachAgent" >> "$LogFile"
	fi
done
# Files
writeLog "Files removed:"
[[ -d "/usr/local/clamXav" ]] && rm -rf "/usr/local/clamXav/" && echo "/usr/local/clamXav/" >> "$LogFile"
[[ -e "/Applications/ClamXav.app" ]] && rm -rf "/Applications/ClamXav.app" && echo "/Applications/ClamXav.app" >> "$LogFile"
[[ -e "/Users/$ConsoleUser/Applications/ClamXav.app" ]] && rm -rf "/Users/$ConsoleUser/Applications/ClamXav.app" && echo "/Users/$ConsoleUser/Applications/ClamXav.app" >> "$LogFile"
# Receipts
writeLog "Receipts removed:"
ReceiptList=$(pkgutil --packages | grep "clamav")
ReceiptList+=$(pkgutil --packages | grep "ClamAV")
for EachReceipt in "${ReceiptList[@]}"; do
	pkgutil --forget "$EachReceipt" >> "$LogFile"
done

## FOOTER
exit 0
