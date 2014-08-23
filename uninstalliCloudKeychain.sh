#!/usr/bin/env bash

## HEADER
# Package Title: iCloud Blocker 1.0
# Author: Conor Schutzman <conor@mac.com>

## DEFINITIONS
SoftwareTitle=iCloudBlocker
LogFile="/Library/Logs/$SoftwareTitle.log"
TimeStamp=$(date "+%Y %b %d %T")
ConsoleUser=$(stat -f %Su "/dev/console")
HostFile="/private/etc/hosts"
iCloudBlocked=$(cat "$HostsFile" | grep -c "icloud")

## LOGGING
writeLog(){ echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$ConsoleUser] [$ScriptTitle] $1" >> "$LogFile"; }
[[ -e "$(dirname "$LogFile")" ]] || mkdir -p -m 775 "$(dirname "$LogFile")"
[[ "$(stat -f%z "$LogFile")" -ge 1000000 ]] && rm -rf "$LogFile"

## BODY
# backup existing log file
[[ -e "$HostFile" ]] && ditto -v "$HostFile" "/Library/CiscoIT/Backup" >> "$LogFile"
# if current hosts file already has all the entries, then exit gracefully
if [[ "$iCloudBlocked" -eq 24 ]]; then
	exit 0
# if current hosts file doesn't have any iCloud entries, append them
elif [[ "$iCloudBlocked" -eq 0 ]]; then
	writeLog "Reconfiguring $HostFile"
	echo "##" >> "$HostFile"
	echo "# Block the following hosts" >> "$HostFile"
# need branching logic because of URLs having leading 0 for 01-09
	for (( i = 1; i < 25; i++ )); do
		[[ "$i" -lt 10 ]] && echo "127.0.0.1 p0$i-escrowproxy.icloud.com" >> "$HostFile"
		[[ "$i" -ge 10 ]] && echo "127.0.0.1 p$i-escrowproxy.icloud.com" >> "$HostFile"
	done
else
	writeLog "Total iCloud entries found: $iCloudBlocked"
fi

## FOOTER
exit 0