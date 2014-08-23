#!/usr/bin/env bash

## HEADER
# Package Title: VMware Fusion 6.02
# Author: Conor Schutzman <conor@mac.com>

## DEFINITIONS
SoftwareTitle=VMware
LogFolder="/Library/Logs/CiscoIT"
LogFile="/Library/Logs/$SoftwareTitle.log"
TimeStamp=$(date "+%Y %b %d %T")
ConsoleUser=$(stat -f %Su "$3/dev/console")
AppLocation="/Applications/VMware Fusion.app"
LicenseKey=0

## ARRAYS
FusionFolders=(
	'Library/Preferences/VMware Fusion'
	'Library/Application Support/VMware'
	'Library/Application Support/VMware/VMware Fusion'
	)
FusionFiles=(
	"Library/Preferences/VMware Fusion/preferences"
	"Library/Preferences/com.vmware.fusion.plist"
	)

## LOGGING
writeLog(){ echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$ConsoleUser] [$ScriptTitle] $1" >> "$LogFile"; }
[[ -e "$(dirname "$LogFile")" ]] || mkdir -p -m 775 "$(dirname "$LogFile")"
[[ "$(stat -f%z "$LogFile")" -ge 1000000 ]] && rm -rf "$LogFile"

## BODY-
writeLog "Creating folders:"
for EachFolder in "${FusionFolders[@]}"; do
	[[ -d "$EachFolder" ]] || mkdir -v -m 755 "$EachFolder" >> "$LogFile"
	[[ -d "/Users/$ConsoleUser/$EachFolder" ]] || sudo -u "$ConsoleUser" mkdir -v -m 755 "/Users/$ConsoleUser/$EachFolder" >> "$LogFile"
done
[[ -e "/Library/Preferences/VMware Fusion/config" ]] || touch -f "/Library/Preferences/VMware Fusion/config"
for EachFile in "${FusionFiles[@]}"; do
	[[ -f "$EachFile" ]] || touch -f "$EachFile"
	[[ -f "/Users/$ConsoleUser/$EachFile" ]] || touch -f "/Users/$ConsoleUser/$EachFile"
done

## LICENSE
if [ "$LicenseKey" != '' ]; then
	echo "$LicenseKey" >> "$(mdfind -onlyin /Applications -name Fusion | head -n 1)/Contents/Library/License Key.txt"
   "$(mdfind -onlyin /Applications -name Fusion | head -n 1)/Contents/Library/License Key.txt" enter "$LicenseKey" '' '' \
                                      '6.0' 'VMware Fusion for Mac OS' '' \
      | grep -q '200 License operation succeeded.'
fi

## FOOTER
exit 0
