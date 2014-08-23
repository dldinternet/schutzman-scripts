#!/usr/bin/env bash

## HEADER
# Package Title: Remove Office 1.4
# Author: Conor Schutzman <conor@mac.com>

## DEFINITIONS
SoftwareTitle=Office
LogFile="/Library/Logs/$SoftwareTitle.log"
TimeStamp=`date "+%Y %b %d %T"`
ConsoleUser=$(stat -f %Su "/dev/console")
UninstallLog="/Library/Logs/OfficeUninstall.log"

## LOGGING
writeLog(){ echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$ConsoleUser] [$ScriptTitle] $1" >> "$UninstallLog"; }
[[ -e "$(dirname "$LogFile")" ]] || mkdir -p -m 775 "$(dirname "$LogFile")"
[[ "$(stat -f%z "$LogFile")" -ge 1000000 ]] && rm -rf "$LogFile"
[[ "$(stat -f%z "$UninstallLog")" -ge 1000000 ]] && rm -rf "$UninstallLog"

# ARRAYS
OfficeFiles=(
	'/Applications/Microsoft Office 2011'
	'/Applications/Microsoft Communicator.app'
	'/Applications/Microsoft Lync.app'
	'/Applications/Microsoft Messenger.app'
	'/Library/Application Support/Microsoft'
	'/tmp/Microsoft'
	'/Library/Fonts/Microsoft'
	'/Library/LaunchDaemons/com.microsoft.office.licensing.helper.plist'
	'/Library/PrivilegedHelperTools/com.microsoft.office.licensing.helper'
	'/Library/Preferences/com.microsoft.office.licensing.plist'
	'/Library/Internet Plug-Ins/SharePointBrowserPlugin.plugin'
	'/Library/Internet Plug-Ins/SharePointWebKitPlugin.plugin'
	'/Library/Internet Plug-Ins/MeetingJoinPlugin.plugin'
	)
SystemPrefs=("/Library/Preferences/com.microsoft"*.plist)
UserPrefs=("/Users/$ConsoleUser/Library/Preferences/com.microsoft"*.plist)
AutomatorActions=()

## BODY
echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$ConsoleUser] [$ScriptTitle] Uninstallation log available at:" >> "$LogFile"
echo "$UninstallLog" >> "$LogFile"
writeLog "Removing Files:"
for EachFile in "${OfficeFiles[@]}"; do
	[[ -e "$EachFile" ]] && rm -rfv "$EachFile" >> "$UninstallLog"
	[[ -e "/Users/$ConsoleUser/$EachFile" ]] && rm -rfv "/Users/$ConsoleUser/$EachFile" >> "$UninstallLog"
done
writeLog "Removing Preferences:"
[[ -d "/Library/Preferences/Microsoft" ]] && rm -rfv "/Library/Preferences/Microsoft" >> "$UninstallLog"
for EachSysPref in "${SystemPrefs[@]}"; do
	[[ -f "$EachSysPref" ]] && rm -rfv "$EachSysPref" >> "$UninstallLog"
done
if [[ "$ConsoleUser" != "root" ]]; then
	[[ -d "/Users/$ConsoleUser/Library/Preferences/Microsoft" ]] && rm -rfv "/Users/$ConsoleUser/Library/Preferences/Microsoft" >> "$UninstallLog"
	for EachUserPref in "${UserPrefs[@]}"; do
		[[ -f "$EachUserPref" ]] && rm -rfv "$EachUserPref" >> "$UninstallLog"
	done
fi
writeLog "Removing Automator actions:"
AutomatorPackages=$(pkgutil --packages | grep microsoft.office | grep automator)
for EachPackage in "${AutomatorPackages[@]}"; do
	while read; do
		AutomatorActions+=("$REPLY")
	done < <(pkgutil --files $EachPackage)
done
for EachAction in "${AutomatorActions[@]}"; do
	if [[ "$EachAction" != "Library" ]] && [[ "$EachAction" != "Library/Automator" ]]; then
		[[ -e "$EachAction" ]] && rm -rfv "$EachAction" >> "$UninstallLog"
	fi
done
writeLog "Removing Receipts:"
ReceiptList=$(pkgutil --packages | grep microsoft)
for EachReceipt in ${ReceiptList[@]}; do
	pkgutil --forget $EachReceipt >> "$UninstallLog"
done

## FOOTER
exit 0
