#!/usr/bin/env bash

## DEFINITIONS
SoftwareTitle=UserFix
LogFile="/Library/Logs/$SoftwareTitle.log"
TimeStamp=`date "+%Y %b %d %T"`
ConsoleUser=$(stat -f %Su '/dev/console')
LogSize=$(stat -f%z "$LogFile")
MaxSize=1000000

## LOGGING
writeLog(){ echo "[$TimeStamp] [$ConsoleUser] $1" >> "$LogFile"; }
[[ -e "$(dirname "$LogFile")" ]] || mkdir -p -m 775 "$(dirname "$LogFile")"
[[ "$(stat -f%z "$LogFile")" -ge 1000000 ]] && rm -rf "$LogFile"

## BODY
if [[ "$(dscl . -list /Users | grep -c $ConsoleUser)" -gt 0 ]] && [[ "$(stat -f %z "/private/var/db/dslocal/nodes/Default/users/$ConsoleUser.plist")" -gt 0 ]]; then
	writeLog "User is found"
else
	writeLog "User missing, implimenting fix"
	dscl . -create /Users/"$ConsoleUser" GeneratedUID "$ConsoleUser"
	dscl . -create /Users/"$ConsoleUser" NFSHomeDirectory "/Users/$ConsoleUser"
	dscl . -create /Users/"$ConsoleUser" PrimaryGroupID 20
	dscl . -create /Users/"$ConsoleUser" RealName "$ConsoleUser"
	dscl . -create /Users/"$ConsoleUser" UserShell /bin/bash
	dscl . -create /Users/"$ConsoleUser" UniqueID "$(stat -f %u '/dev/console')"
fi

exit 0