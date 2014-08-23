#!/usr/bin/env bash

## HEADER
# Package Title: Configure OS X Settings 20140822
# Author: Conor Schutzman <conor@mac.com>

## DEFINITIONS
SoftwareTitle=OSSettings
SectionTitle=Initialization
LogFile="/Library/Logs/$SoftwareTitle.log"
TimeStamp=$(date "+%Y %b %d %T")
ConsoleUser=$(stat -f %Su "/dev/console")
OSXvers="$(sw_vers -productVersion | awk -F. '{print $2}')"
TCCdatabase="/Library/Application Support/com.apple.TCC/TCC.db"
BackupFolder="/Library/Backup"
LoginPrefs="/Library/Preferences/com.apple.loginwindow.plist"
ASAprefs="/System/Library/User Template/English.lprog/Library/Preferences/com.apple.SetupAssistant.plist"
ASUprefs="/Library/Preferences/com.apple.SoftwareUpdate.plist"
SSHprefs="/private/etc/sshd_config"

## LOGGING
writeLog(){ echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$ConsoleUser] [$ScriptTitle] [$SectionTitle] $1" >> "$LogFile"; }
[[ -e "$(dirname "$LogFile")" ]] || mkdir -p -m 775 "$(dirname "$LogFile")"
[[ "$(stat -f%z "$LogFile")" -ge 1000000 ]] && rm -rf "$LogFile"

## INFRASTRUCTURE
[[ -d "$BackupFolder" ]] || mkdir -p "$BackupFolder"

## PREFERENCES
SectionTitle=Preferences
# Firewall ON
CurrentFirewall=$(defaults read "/Library/Preferences/com.apple.alf" globalstate)
if [[ "$CurrentFirewall" -ne 1 ]]; then
	writeLog "Firewall ON"
	defaults write "/Library/Preferences/com.apple.alf" globalstate -int 1
fi
# Firewall logging ON
CurrentFWLogging=$(defaults read "/Library/Preferences/com.apple.alf" loggingenabled)
if [[ "$CurrentFWLogging" -ne 1 ]]; then
	writeLog "Firewall logging ON"
	defaults write "/Library/Preferences/com.apple.alf" loggingenabled -bool true
fi
# iCloud Default Save Dialog OFF
CurrentCloudSave=$(defaults read NSGlobalDomain NSDocumentSaveNewDocumentsToCloud)
if [[ "$CurrentCloudSave" -ne 0 ]]; then
writeLog "iCloud Default Save Dialog OFF"
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
fi
# GateKeeper Mac App Store and Identified Developers ON
CurrentGatekeeper=$(spctl --status | grep -c enabled)
if [[ "$CurrentGatekeeper" -ne 1 ]]; then
	writeLog "GateKeeper Mac App Store and Identified Developers ON"
	defaults write "/var/db/SystemPolicy-prefs.plist" enabled -string yes
	defaults write com.apple.LaunchServices LSQuarantine -bool true
	spctl --master-enable
	spctl --enable --label "Mac App Store"
	spctl --enable --label "Developer ID"
fi
# Show Scrollbars ON
CurrentScrollBar=$(defaults read "/System/Library/User Template/Non_localized/Library/Preferences/.GlobalPreferences.plist" AppleShowScrollBars | grep -c "Always")
if [[ "$CurrentScrollBar" -ne 1 ]]; then
	writeLog "Show Scrollbars ON"
	defaults write "/System/Library/User Template/Non_localized/Library/Preferences/.GlobalPreferences.plist" AppleShowScrollBars -string Always
fi
# System sleep on A/C power OFF
pmset -c sleep 0

## USER PREFERENCES
SectionTitle=UserPrefs
ConsoleUser=$(stat -f %Su "/dev/console")
if [[ "$ConsoleUser" != "root" ]]; then
# Show Scrollbars ON
	sudo -u "$ConsoleUser" defaults write "/Users/$ConsoleUser/Library/Preferences/.GlobalPreferences.plist" AppleShowScrollBars -string Always
# Homepage SET
	CurrentHomePage=$(defaults read com.apple.Safari HomePage | grep -c apple)
	if [[ "$CurrentHomePage" -ne 1 ]]; then
		writeLog "Homepage SET"
		sudo -u "$ConsoleUser" defaults write com.apple.Safari HomePage http://www.apple.com
	fi
# Safari Top Sites OFF
	CurentSafariNewTab=$(defaults read "/Users/$ConsoleUser/Library/Preferences/com.apple.Safari" NewTabBehavior)
	CurrentSafariNewWindow=$(defaults read "/Users/$ConsoleUser/Library/Preferences/com.apple.Safari" NewWindowBehavior)
	if [[ "$CurrentSafariNewWindow" -ne 0 ]] || [[ "$CurrentSafariNewTab" -ne 0 ]]; then
		writeLog "Safari Top Sites OFF"
		sudo -u "$ConsoleUser" defaults write "/Users/$ConsoleUser/Library/Preferences/com.apple.Safari" NewWindowBehavior -integer 0
		sudo -u "$ConsoleUser" defaults write "/Users/$ConsoleUser/Library/Preferences/com.apple.Safari" NewTabBehavior -integer 0
	fi
fi

## LOGIN WINDOW
SectionTitle=LoginWindow
# # Existing Prefs REMOVED
# [[ -e "$LoginPrefs" ]] && defaults read "$LoginPrefs" >> "$BackupFolder/com.apple.loginwindow.plist"
# [[ -e "$LoginPrefs" ]] && rm -rfv "$LoginPrefs" >> "$LogFile"
# Login Window Banner SET
defaults write "$LoginPrefs" LoginwindowText "This system is for authorized users only. Any use of this system is subject to monitoring."
rm /System/Library/Caches/com.apple.corestorage/EFILoginLocalizations/*.efires
# Automatic Login Off
if [[ "$(defaults read "$LoginPrefs" autoLoginUser)" ]]; then
	writeLog "AutoLogin OFF"
	defaults delete "$LoginPrefs" autoLoginUser
fi
# Hide users with UID under 500 ON
if [[ "$(defaults read "$LoginPrefs" Hide500Users)" -ne 1 ]]; then
	writeLog "Display users with UID under 500 OFF"
	defaults write "$LoginPrefs" Hide500Users -bool true
fi
# "Other" user login option OFF
if [[ "$(defaults read "$LoginPrefs" SHOWOTHERUSERS_MANAGED)" -ne 0 ]]; then
	writeLog "Other user login option OFF"
	defaults write "$LoginPrefs" SHOWOTHERUSERS_MANAGED -bool false
fi
# Name & Password Login Fields OFF
if [[ "$(defaults read "$LoginPrefs" SHOWFULLNAME)" -ne 0 ]]; then
	writeLog "Name & Password Login Fields OFF"
	defaults write "$LoginPrefs" SHOWFULLNAME -bool false
fi

# LoginHook REMOVED
if [[ -z "$(defaults read "$LoginPrefs" LoginHook)" ]]; then
	writeLog "LoginHook REMOVED"
	defaults delete "$LoginPrefs" LoginHook
fi
# LogoutHook REMOVED
CurrentLogoutHook=
if [[ -z "$(defaults read "$LoginPrefs" LogoutHook)" ]]; then
	writeLog "LogoutHook REMOVED"
	defaults delete "$LoginPrefs" LogoutHook
fi
# Input Menu ON
if [[ "$(defaults read "$LoginPrefs" showInputMenu)" -ne 1 ]]; then
	writeLog "Input Menu ON"
	defaults write "$LoginPrefs" showInputMenu -bool true
fi
# Force refresh of loginwindow prefs
rm /System/Library/Caches/com.apple.corestorage/EFILoginLocalizations/*.efires

## NEW USERS
SectionTitle=NewUsers
# iCloud Prompt OFF
if [[ "$(defaults read "$ASAprefs" DidSeeCloudSetup)" -ne 1 ]]; then
	writeLog "iCloud Prompt OFF"
	defaults write "$ASAprefs" DidSeeCloudSetup -bool true
	defaults write "$ASAprefs" LastSeenCloudProductVersion "10.$OSXvers"
fi
# Keychain Sync Prompt OFF
if [[ "$(defaults read "$ASAprefs" DidSeeSyncSetup)" -ne 1 ]] || [[ "$(defaults read "$ASAprefs" DidSeeSyncSetup2)" -ne 1 ]]; then
	writeLog "Keychain Sync Prompt OFF"
	defaults write "$ASAprefs" DidSeeSyncSetup -bool true
	defaults write "$ASAprefs" DidSeeSyncSetup2 -bool true
	defaults write "$ASAprefs" LastSeenSyncProductVersion "10.$OSXvers"
fi
# Natural Scrolling Prompt OFF
if [[ "$(defaults read "$ASAprefs" | grep -c trackpad)" -ne 1 ]]; then
	writeLog "Natural Scrolling Prompt OFF"
	defaults write "$ASAprefs" GestureMovieSeen trackpad
fi

## SHARING
SectionTitle=Sharing
# Screen Sharing OFF
writeLog "Screen Sharing OFF"
srm "/Library/Preferences/com.apple.ScreenSharing.launchd"
# File Sharing OFF
writeLog "File Sharing OFF"
launchctl unload -w "/System/Library/LaunchDaemons/com.apple.AppleFileServer.plist"
# FTP Sharing OFF
writeLog "FTP Sharing OFF"
launchctl unload -w "/System/Library/LaunchDaemons/ftp.plist"
# Remote Login ON
writeLog "Remote Login ON"
launchctl load -w "/System/Library/LaunchDaemons/ssh.plist"
# Remote Management OFF
writeLog "Remote Management OFF"
"/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart" -deactivate -stop
# Remote Apple Events OFF
writeLog "Remote Apple Events OFF"
launchctl unload -w "/System/Library/LaunchDaemons/eppc.plist"
# Web Sharing OFF
writeLog "Web Sharing OFF"
launchctl unload -w "/System/Library/LaunchDaemons/org.apache.httpd.plist"
# Internet Sharing OFF
writeLog "Internet Sharing OFF"
launchctl unload -w "/System/Library/LaunchDaemons/com.apple.InternetSharing.plist"
# Bluetooth Sharing OFF
writeLog "Bluetooth Sharing OFF"
defaults -currentHost write com.apple.bluetooth PrefKeyServicesEnabled -bool false

## APP STORE
SectionTitle=AppStore
# Automatically check for updates ON
if [[ "$(defaults read "$ASUprefs" AutomaticCheckEnabled)" -ne 1 ]]; then
	writeLog "Automatically check for updates ON"
	defaults write "$ASUprefs" AutomaticCheckEnabled -bool true
fi
# Download newly available updates in background ON
if [[ "$(defaults read "$ASUprefs" AutomaticDownload)" -ne 1 ]]; then
	writeLog "Download newly available updates in background ON"
	defaults write "$ASUprefs" AutomaticDownload -bool true
fi
# Install app updates ON
if [[ "$(defaults read "/Library/Preferences/com.apple.storeagent.plist" AutoUpdate)" -ne 1 ]]; then
	writeLog "Install app updates ON"
	defaults write "/Library/Preferences/com.apple.storeagent.plist" AutoUpdate -bool true
fi
# Install system data files and security updates ON
if [[ "$(defaults read "$ASUprefs" ConfigDataInstall)" -ne 1 ]] || [[ $(defaults read "$ASUprefs" CriticalUpdateInstall) -ne 1 ]]; then
	writeLog "Install system data files and security updates ON"
	defaults write "$ASUprefs" ConfigDataInstall -bool true
	defaults write "$ASUprefs" CriticalUpdateInstall -bool true
fi

## SSH
SectionTitle=SSH
[[ -e "$SSHprefs" ]] && cp -npv "$SSHprefs" "$BackupFolder/sshd_config" >> "$LogFile"
# Root Access OFF
if [[ "$(cat "$SSHprefs" | grep -c "#PermitRootLogin")" -gt 0 ]]; then
	writeLog "Root Access OFF - comment removed"
	sed -i.bak 's/#PermitRootLogin.*/PermitRootLogin no/' "$SSHprefs"
elif [[ "$(cat "$SSHprefs" | grep -c "PermitRootLogin yes")" -gt 0 ]]; then
	writeLog "Root Access OFF"
	sed -i.bak 's/PermitRootLogin yes/PermitRootLogin no/' "$SSHprefs"
elif [[ "$(cat "$SSHprefs" | grep -c "PermitRootLogin")" -eq 0 ]]; then
	writeLog "Root Access OFF - entry added"
	echo "" >> "$SSHprefs"
	echo "PermitRootLogin no" >> "$SSHprefs"
fi
# Allow Empty Passwords OFF
if [[ "$(cat "$SSHprefs" | grep -c "#PermitEmptyPasswords")" -gt 0 ]]; then
	writeLog "Allow Empty Passwords OFF - comment removed"
	sed -i.bak 's/#PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSHprefs"
elif [[ "$(cat "$SSHprefs" | grep -c "PermitEmptyPasswords yes")" -gt 0 ]]; then
	writeLog "Allow Empty Passwords OFF"
	sed -i.bak 's/PermitEmptyPasswords yes/PermitEmptyPasswords no/' "$SSHprefs"
elif [[ "$(cat "$SSHprefs" | grep -c "PermitEmptyPasswords")" -eq 0 ]]; then
	writeLog "Allow Empty Passwords OFF - entry added"
	echo "" >> "$SSHprefs"
	echo "PermitEmptyPasswords no" >> "$SSHprefs"
fi
# SSH Banner SET
if [[ "$(cat "$SSHprefs" | grep -c "#Banner none")" -gt 0 ]] && [[ "$(cat "$SSHprefs" | grep -c "/etc/sshbanner")" -eq 0 ]]; then
	writeLog "SSH Banner SET - comment removed"
	sed -i.bak 's/#Banner none/Banner \/etc\/sshbanner/' "$SSHprefs"
elif [[ "$(cat "$SSHprefs" | grep -c "#Banner none")" -eq 0 ]] && [[ "$(cat "$SSHprefs" | grep -c "/etc/sshbanner")" -eq 0 ]]; then
	writeLog "SSH Banner SET - entry added"
	echo "#" >> "$SSHprefs"
	echo "Banner /etc/sshbanner" >> "$SSHprefs"
fi
[[ -e "/etc/sshbanner" ]] && rm -rf "/etc/sshbanner"
cat > "/etc/sshbanner" << _EOF_

	WARNING !!! READ THIS BEFORE ATTEMPTING TO LOGON !!!

	This System is for the use of authorized users only.  Individuals using
this computer without authority, or in excess of their authority, are subject
to having all of their activities on this system monitored and recorded by
system personnel.

	In the course of monitoring individuals improperly using this system, or
in the course of system maintenance, the activities of authorized users may
also be monitored.  Anyone using this system expressly consents to such
monitoring and is advised that if such monitoring reveals possible criminal
activity, system personnel may provide the evidence of such monitoring to law
enforcement officials.

_EOF_

## FOOTER
defaults read "$LoginPrefs" >> "/private/tmp/com.apple.loginwindow.plist"
exit 0