#!/usr/bin/env bash

## HEADER
# Package Title: Casper Daemon 4.4
# Author: Conor Schutzman <conor@mac.com>

## DEFINITIONS
SoftwareTitle=CasperDaemon
LogFile="/Library/Logs/$SoftwareTitle.log"
TimeStamp=$(date "+%Y %b %d %T")
ConsoleUser=$(stat -f %Su "$3/dev/console")

## ARRAYS
ToBeUnloaded=(
	'/Library/LaunchAgents/com.jamfsoftware.jamf.agent.plist'
	'/Library/LaunchDaemons/com.jamfsoftware.jamf.daemon.plist'
	'/Library/LaunchDaemons/com.jamfsoftware.startupItem.plist'
	'/Library/LaunchDaemons/com.jamfsoftware.task.1.plist'
	)
CasperFiles=(
	'/usr/sbin/jamf'
	'/tmp/casper.zip'
	'/Library/Preferences/com.jamfsoftware.jamf.plist'
	'/Library/Application Support/jamf'
	)

## LOGGING
writeLog(){ echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$ConsoleUser] [$ScriptTitle] $1" >> "$LogFile"; }
[[ -e "$(dirname "$LogFile")" ]] || mkdir -p -m 775 "$(dirname "$LogFile")"
[[ "$(stat -f%z "$LogFile")" -ge 1000000 ]] && rm -rf "$LogFile"

## BODY
writeLog "Unloading and removing:"
for EachUnload in "${ToBeUnloaded[@]}"; do
	launchctl unload "$EachUnload"
	sudo -u "$ConsoleUser" launchctl unload "$EachUnload"
	[[ -e "$EachUnload" ]] && rm -rfv "$EachUnload" >> "$LogFile"
	[[ -e "/Users/$ConsoleUser/$EachUnload" ]] && rm -rfv "/Users/$ConsoleUser/$EachUnload" >> "$LogFile"
done
writeLog "Removing damaged files:"
if [[ -e "/usr/sbin/jamf" ]]; then
	jamf -removeFramework
	echo "removing jamf framework" >> "$LogFile"
fi
for EachFile in "${CasperFiles[@]}"; do
	[[ -e "/$EachFile" ]] && rm -rfv  "$EachFile" >> "$LogFile"
	[[ -e "/Users/$ConsoleUser/$EachFile" ]] && rm -rfv  "/Users/$ConsoleUser/$EachFile" >> "$LogFile"
done
if [[ $(pkgutil --packages | grep -c casper) -gt 0 ]]; then
	ReceiptList=$(pkgutil --packages | grep casper)
	ReceiptList+=$(pkgutil --packages | grep jamf)
	writeLog "Removing receipts:"
	for EachReceipt in "${ReceiptList[@]}"; do
		pkgutil --forget "$EachReceipt" >> "$LogFile"
	done
fi

## FOOTER
exit 0
