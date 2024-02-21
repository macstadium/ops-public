#!/bin/bash

user=$(whoami)
no_pass_config="$user ALL=(ALL) NOPASSWD:ALL"
config_file=/etc/sudoers.d/$user


### Allow running sudo with no password

sudo touch $config_file
sudo grep -qxF "$no_pass_config" $config_file || echo $no_pass_config | sudo tee -a $config_file
sudo chmod 0440 $config_file


### Host Level config

## Enable automatic login
sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser $user
## Set Computer To Sleep Never
sudo pmset sleep 0
## Set Display To Sleep Never
sudo pmset -a displaysleep 0
## Set Disk To Sleep Never
sudo pmset -a disksleep 0
## Enable Wake For Network Access
sudo pmset -a womp 1
## Enable Start Up Automatically after a power Failure
sudo pmset -a autorestart 1
## Get Wi-Fi interface name
wifi_interface=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort|Wireless/{getline; print $2}')
## Disable Wi-Fi
sudo networksetup -setairportpower $wifi_interface off
## Disable Wi-Fi Service
sudo networksetup -setnetworkserviceenabled Wi-Fi off
## Remove the history of Wifi (If it Fails that means there is no history)
sudo defaults delete /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
## Enable Remote Management (requires a reboot)
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -on -restart -privs -all -allowAccessFor -allUsers
## ARP Fix
sudo nvram bcm-ethernet-options=Batch_ARP_Enable=false
## Remove history 
sudo rm -rf ~/.zsh_sessions/*


## SSH Key

ssh_dir=$HOME/.ssh
authorized_keys_file=$ssh_dir/authorized_keys
authorized_key='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC1UFSShiNqAI+zzkL/NFAveVi+OB8S7EM4duQxStNsybKg8fmvFaEoBqy7jjOsNpvWNXBCm3RWzshpfeWnApFcLMndch4ziq+SfkViqLhRz5hV58/RSrA22F1KEqtoAxkE4giYWFp4uzSn5jQL3yAunqtiJDQ2MtkD1PVhlgndSjzr9X6SvGkPge1TccTAhgkNWWHB8vYG2YlNidblT5PTGwp/Jd7u/i3RsTe3RheVdLM2sThdHMMenilGo89SZEH18xhZibaUuwp5RABIJgXUWne320t7FOuj7uKEJoep5CSCeUqQKuUZ8lW8GayMubjAFi9zgkdFrwp2EAWA8TFw9gqb+6cheYVX1edxNjkmjD9xUZ3AMqm0X5/cAh4HaYFkVDcWRMY0bEq8YMAQDxM8U3Du3V1+UV2yi+Tjf9jgMV3kvm9INl3s3u5hn3JS0Au35It2H20S+EYY2rlphK5gb3uvCQv/pddqYA2MXa5pMi00xKBiFL1eiRPLLsgI7m5w5Kjt2TetnMHgM9t1e6dKJGy/bJlQHm/mkhV7iPIstnDl5j60cXa8srM0zXpzCew9yjQHGKY2fHlN5b40InPYdSYXApTDxArsdDdxmdEoN8KCDfJ8FUKzlhM0h3WbD91saulzt5jQIGEIpIL2E3ONXg93DnAPGhZRD4KwmgbFGw== alexkingston@akingston-03NQ'

if [ ! -d $ssh_dir ]; then
    mkdir $ssh_dir
    chmod 700 $ssh_dir
fi

touch $authorized_keys_file
grep -qxF "$authorized_key" $authorized_keys_file || echo "$authorized_key" | tee -a $authorized_keys_file
chmod 600 $authorized_keys_file

## remove the sudeor file
script_path=$(realpath "$0")  # Get the absolute path of the script
rm -f "$script_path"
history -c


## Install brew as well as Xcode Command Line Tools

echo '' | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"


## pause for brew installation

Sleep 20

## Add brew to path

(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/administrator/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"


## Install Blueutil to disable bluetooth
brew install blueutil


## Pause for Blueutil to install

Sleep 12

## Disable bluetooth

blueutil --power 0

## Remove Blueutil

brew uninstall blueutil
rm -rf ~/Library/Caches/homebrew/blueutil-*
rm -rf ~/Library/Logs/Homebrew/blueutil
