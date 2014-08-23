#!/usr/bin/env bash

## HEADER
# Package Title: Jamf Casper 9.32
# Script Title: Casper Daemon 4.5
# Author: Conor Schutzman <conor@mac.com>

## DEFINITIONS
SoftwareTitle=CasperDaemon
LogFile="/Library/Logs/$SoftwareTitle.log"
TimeStamp=$(date "+%Y %b %d %T")
ConsoleUser=$(stat -f %Su "/dev/console")

## LOGGING
writeLog(){ echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$ConsoleUser] [$ScriptTitle] [$SectionTitle] $1" >> "$LogFile"; }
[[ -e "$(dirname "$LogFile")" ]] || mkdir -p -m 775 "$(dirname "$LogFile")"
[[ "$(stat -f%z "$LogFile")" -ge 1000000 ]] && rm -rf "$LogFile"

## LOADING PREFERENCES
DaemonPrefs="/Library/Preferences/com.casperdaemon.plist"
CasperVersion=$(defaults read $DaemonPrefs casper_version)
JSSserver=$(defaults read $DaemonPrefs jss_url)
JSSport=$(defaults read $DaemonPrefs jss_port)
InviteID=$(defaults read $DaemonPrefs invite_code)
PackageFolder=$(defaults read $DaemonPrefs package_folder)
FilerURL=$(defaults read $DaemonPrefs filer_url)

## ARRAY
CasperFiles=(
	'/usr/sbin/jamf'
	'/Library/Preferences/com.jamfsoftware.jamf.plist'
	'/Library/LaunchDaemons/com.jamfsoftware.jamf.daemon.plist'
	'/Library/LaunchDaemons/com.jamfsoftware.startupItem.plist'
	'/Library/LaunchDaemons/com.jamfsoftware.task.1.plist'
	'/Library/LaunchAgents/com.jamfsoftware.jamf.agent.plist'
	'/Library/Application Support/jamf'
	'/Library/Preferences/com.jamfsoftware.jss.plist'
	)

## FUNCTIONS
VerifyConnection(){ curl -L -s -o /dev/null --silent --head --write-out '%{http_code}' "$FilerURL/" --location-trusted -X GET; }

## BODY
[[ -e "/private/tmp/DaemonVersion.txt" ]] && rm -rf "/private/tmp/DaemonVersion.txt"
[[ -e "/private/tmp/BinaryVersion.txt" ]] && rm -rf "/private/tmp/BinaryVersion.txt"
# Check for Casper present and running
if [[ "$(ps aux | grep -c '[j]amf')" > 0 ]] && [[ -e "/usr/sbin/jamf" ]]; then
	if [[ "$(defaults read "$DaemonPrefs" verify_recon)" = 1 ]]; then
		jamf recon  >> "$LogFile" && defaults delete "$DaemonPrefs" verify_recon
	fi
	exit 0
fi
# Remove previous Casper files
SectionTitle=Uninstall
writeLog "Removing files:"
[[ -e "/usr/sbin/jamf" ]] && jamf -removeFramework
for EachFile in "${CasperFiles[@]}"; do
	[[ -e "$EachFile" ]] && rm -rfv "$EachFile" >> "$LogFile"
done
defaults delete "$DaemonPrefs" date_renrolled
defaults delete "$DaemonPrefs" verify_recon
# Compare version on system with latest version on ACNS
SectionTitle=Connection
if [[ "$(VerifyConnection)" -eq 200 ]]; then
	curl -L "$FilerURL/JAMF/Daemon/ITPackaged/version.txt" -o "/private/tmp/DaemonVersion.txt" --location-trusted
	curl -L "$FilerURL/JAMF/Binary/ITPackaged/version.txt" -o "/private/tmp/BinaryVersion.txt" --location-trusted
	CurrentVersion=$(cat "/private/tmp/DaemonVersion.txt" | grep "Prod" | grep -o [0-9][.][0-9])
	BinaryVersion=$(cat "/private/tmp/BinaryVersion.txt" | grep "Prod" | grep -o [0-9][.][0-9])
else
	writeLog "Connection error"
	exit 1
fi
# Download and install newer Daemon version from ACNS
SectionTitle=Daemon
if [[ "$CurrentVersion" > "$DaemonVersion" ]]; then
	writeLog "ACNS version: $CurrentVersion"
	writeLog "Installed version: $DaemonVersion"
	if [[ "$(VerifyConnection)" -eq 200 ]]; then
		curl -L "$FilerURL/JAMF/Daemon/ITPackaged/$CurrentVersion/CasperDaemon_$CurrentVersion.pkg" -o "$PackageFolder/CasperDaemon_$CurrentVersion.pkg" --location-trusted >> "$LogFile"
		if [[ -e "$PackageFolder/CasperDaemon_$CurrentVersion.pkg" ]]; then
			installer -dumplog -verbose -pkg "$PackageFolder/CasperDaemon_$CurrentVersion.pkg" -target "/" -allowUntrusted >> "$LogFile"
		else
			writeLog "Download error"
			exit 1
		fi
	fi
	exit 0
fi
# Download newer Binary version from ACNS
SectionTitle=Binary
if [[ "$BinaryVersion" > "$CasperVersion" ]] || [[ ! -e "$PackageFolder/JamfCasperBinary_$CasperVersion.pkg" ]]; then
	writeLog "ACNS version: $BinaryVersion"
	writeLog "Installed version: $CasperVersion"
	if [[ "$(VerifyConnection)" -eq 200 ]]; then
		curl -L "$FilerURL/JAMF/Binary/ITPackaged/$BinaryVersion/JamfCasperBinary_$BinaryVersion.pkg" -o "$PackageFolder/JamfCasperBinary_$BinaryVersion.pkg" --location-trusted >> "$LogFile"
		defaults write "$DaemonPrefs" casper_version "$BinaryVersion"
		CasperVersion=$(defaults read "$DaemonPrefs" casper_version)
	fi
fi
# Reinstall Binary
if [[ -e "$PackageFolder/JamfCasperBinary_$CasperVersion.pkg" ]]; then
	writeLog "Install required"
	installer -dumplog -verbose -pkg "$PackageFolder/JamfCasperBinary_$CasperVersion.pkg" -target "/" -allowUntrusted >> "$LogFile"
else
	writeLog "Download error"
	exit 1
fi
# Enrollment
SectionTitle=Enrollment
if [[ -e "/usr/sbin/jamf" ]]; then
	if [[ "$(nc -z "$JSSserver" "$JSSport" | grep -c "succeeded")" > 0 ]]; then
		writeLog "Enrolling with JSS"
		defaults write "$DaemonPrefs" verify_recon -bool TRUE
		jamf createConf -url "https://$JSSserver:$JSSport" >> "$LogFile"
		jamf enroll -invitation "$InviteID" >> "$LogFile"
		# jamf policy -event validateManagement -noRecon >> "$LogFile"
		defaults write "$DaemonPrefs" date_renrolled "$TimeStamp"
		writeLog "Enrollment complete"
	else
		writeLog "Unable to communicate with JSS Server."
		exit 1
	fi
else
	writeLog "Installation not successful."
fi

## FOOTER
exit 0
