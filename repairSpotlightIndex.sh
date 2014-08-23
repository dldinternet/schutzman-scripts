#!/usr/bin/env bash

## HEADER
# Package Title: Spotlight Reindex 1.2
# Author: Conor Schutzman <conor@mac.com>
SoftwareTitle=Spotlight
LogFile="/Library/Logs/$SoftwareTitle.log"
TimeStamp=$(date "+%a %b%e %Y %T")
OfficeFolder=$(mdfind -onlyin '/Applications' -name Microsoft | grep Office | grep 2011 | head -n 1)

## LOGGING
writeLog(){ echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$ConsoleUser] [$ScriptTitle] $1" >> "$LogFile"; }
[[ -e "$(dirname "$LogFile")" ]] || mkdir -p -m 775 "$(dirname "$LogFile")"
[[ "$(stat -f%z "$LogFile")" -ge 1000000 ]] && rm -rf "$LogFile"

## FOLDER PERMISSIONS
if [[ "$(stat -f %u "$OfficeFolder")" = 0 ]] && [[ "$(stat -f %g "$OfficeFolder")" = 0 ]] && [[ $(stat -f %p "$OfficeFolder") = 40755 ]]; then
	writeLog "$OfficeFolder verified, no permission changes required."
else
	writeLog "$OfficeFolder will need to be modified."
	[[ "$(stat -f %u "$OfficeFolder")" = 0 ]] || chown 0 "$OfficeFolder" >> "$LogFile"
	[[ "$(stat -f %g "$OfficeFolder")" = 0 ]] || chgrp 0 "$OfficeFolder" >> "$LogFile"
	[[ $(stat -f %p "$OfficeFolder") = 40755 ]] || chmod -vv 755 "$OfficeFolder" >> "$LogFile"
fi

## SPOTLIGHT INDEX
writeLog "Stopping Spotlight indexing."
mdutil -a -i off
writeLog "Deleting previous Spotlight index."
[[ -e "/.Spotlight-V100" ]] && rm -rfv "$3/.Spotlight-V100"
writeLog "Resuming Spotlight indexing."
mdutil -a -i on

## FOOTER
exit 0
