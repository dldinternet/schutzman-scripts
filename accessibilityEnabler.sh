#!/usr/bin/env bash

## HEADER
# Script: Accessibility Enabler 1.4
# Author: Conor Schutzman <conor@mac.com>

## DEFINITIONS
ConsoleUser="$(stat -f %Su "/dev/console")"
TCCdatabase="/Library/Application Support/com.apple.TCC/TCC.db"

## ARRAYS
ApplicaitonIdentifiers=(
	'com.apple.systemevents'
	'com.apple.terminal'
	)

## BODY
echo "OS X Version: $(sw_vers -productVersion)"
if [[ "$(sw_vers -productVersion | awk -F. '{print $1}')" -lt 9 ]]; then
	echo -n "a" &> "/private/var/db/.AccessibilityAPIEnabled"
	chmod 444 "/private/var/db/.AccessibilityAPIEnabled"
else
	for EachApp in "${ApplicaitonIdentifiers[@]}"; do
		sqlite3 "$TCCdatabase" "INSERT or REPLACE into 'access' VALUES('kTCCServiceAccessibility','$EachApp',0,1,0,NULL);" 2>&1
	done
fi

## FOOTER
exit 0
