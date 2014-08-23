#!/usr/bin/env bash

## HEADER
# Package Title: WebEx Tool for Mac 3.1
# Author: Conor Schutzman <conor@mac.com>

## DEFINITIONS
SoftwareTitle=WebExTool
SectionTitle=Postflight
LogFile="/Library/Logs/$SoftwareTitle.log"
TimeStamp=$(date "+%Y %b %d %T")
ConsoleUser=$(stat -f %Su "$3/dev/console")
ResourceLocation=$(dirname "$0")
AppLocation=$(mdfind -onlyin /Applications -name WebEx  | grep Tool | head -n 1)
ScriptLocation="/Users/$ConsoleUser/Library/Application Support/Microsoft/Office/Outlook Script Menu Items/"
TCCdatabase="/Library/Application Support/com.apple.TCC/TCC.db"
ALFbinary='/usr/libexec/ApplicationFirewall/socketfilterfw'

## LOGGING
writeLog(){ echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$ConsoleUser] [$ScriptTitle] [$SectionTitle] $1" >> "$LogFile"; }
[[ -e "$(dirname "$LogFile")" ]] || mkdir -p -m 775 "$(dirname "$LogFile")"
[[ "$(stat -f%z "$LogFile")" -ge 1000000 ]] && rm -rf "$LogFile"

## EXTRACTION
SectionTitle=Extraction
# expand zip file and deploy
if [[ -e "$ResourceLocation/webex.zip" ]]; then
	writeLog "Deploying:"
	ditto -v -V -x -k --sequesterRsrc --rsrc "$ResourceLocation/webex.zip" "$3/Applications/" 2>&1 | head -n 1 >> "$LogFile"
else
	writeLog "File not found: webex.zip"
	ls "$ResourceLocation" >> "$LogFile"
fi
if [[ -e "$3/$AppLocation" ]]; then
	writeLog "Modifying permissions"
	chown -R root:wheel "$3/$AppLocation"
	chmod -vv -R 775 "$3/$AppLocation" | head -n 1 >> "$LogFile"
else
	writeLog "File not found: $AppLocation"
fi

## CODESIGNING
SectionTitle=Gatekeeper
# verify signature of installed app
if	[[ -e "$3/$AppLocation" ]]; then
	writeLog "Verifying:"
	codesign -vvv "$3/$AppLocation" >> "$LogFile" 2>&1
	SignValid=$(tail -n 1 "$LogFile" | grep -c "satisfies its Designated Requirement")
	if [[ $SignValid > 0 ]]; then
# force GateKeeper to see the application as launchable
		writeLog "Adding Gatekeeper exception"
		spctl -vv --add "$3/$AppLocation" >> "$LogFile" 2>&1
# clear quarentine flag from application
		writeLog "Clearing quarentine flag"
		xattr -d com.apple.quarantine "$3/$AppLocation" >> "$LogFile" 2>&1
	fi
else
	writeLog "File not found: $AppLocation"
fi
# force ALF to allow all signed apps
"$ALFbinary" --setallowsigned on >> "$LogFile" 2>&1

## APPLESCRIPT
SectionTitle=AppleScript
# expand AppleScript file from inside the app bundle and installing it in outlook folder
if [[ -e "$3/$AppLocation/Contents/Resources/WebEx Tool for Mac.zip" ]]; then
	writeLog "Deploying:"
	ditto -v -V -x -k --sequesterRsrc --rsrc "$3/$AppLocation/Contents/Resources/WebEx Tool for Mac.zip" "$3/$ScriptLocation" 2>&1 | head -n 1 >> "$LogFile"
else
	writeLog "File not found: $AppLocation/Contents/Resources/WebEx Tool for Mac.zip"
fi
# set permissions of AppleScript file
if [[ -e "$3/$ScriptLocation/WebEx Tool for Mac.scpt" ]]; then
	writeLog "Modifying permissions"
	chown -R "$ConsoleUser":staff "$3/$ScriptLocation/WebEx Tool for Mac.scpt"
	chmod -vv -R 775 "$3/$ScriptLocation/WebEx Tool for Mac.scpt" | head -n 1 >> "$LogFile"
else
	writeLog "File not found: $ScriptLocation/WebEx Tool for Mac.scpt"
fi

## ACCESS
SectionTitle=Accessibility
OSXvers=$(sw_vers -productVersion)
writeLog "OS X Version: $OSXvers"
if [[ $OSXvers < 10.9 ]]; then
# toggle assistive device checkbox for older OSes
	writeLog "Enabling assistive devices"
	echo -n "a" &> "/private/var/db/.AccessibilityAPIEnabled"
	chmod 444 "/private/var/db/.AccessibilityAPIEnabled"
else
# update TCC database for newer OSes
	writeLog "Editing TCC Database"
	sqlite3 "$3/$TCCdatabase" "INSERT or REPLACE into 'access' VALUES('kTCCServiceAccessibility','com.cisco.WebEx-Tool-for-Mac',0,1,0,NULL);" >> $LogFile 2>&1
	sqlite3 "$3/$TCCdatabase" "INSERT or REPLACE into 'access' VALUES('kTCCServiceAccessibility','com.apple.systemevents',0,1,0,NULL);" >> $LogFile 2>&1
fi

## FOOTER
exit 0
