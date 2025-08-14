#!/bin/bash

# MacStadium Mac OS QC Script

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m'
BOLD='\033[1m'

# Maximize terminal window
maximize_terminal() {
    
    if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
        osascript -e 'tell application "Terminal"
            set bounds of front window to {0, 0, 9999, 9999}
        end tell' 2>/dev/null
  
    elif [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
        osascript -e 'tell application "iTerm2"
            tell current window
                set fullscreen to true
            end tell
        end tell' 2>/dev/null
    
    else
        printf '\e[8;999;999t' 2>/dev/null
    fi
    
    
    clear
}

print_header() {
    echo -e "\n${BLUE}${BOLD}════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}${BOLD}  $1${NC}"
    echo -e "${BLUE}${BOLD}════════════════════════════════════════════════${NC}"
}

print_info() {
    printf "%-30s: %s\n" "$1" "$2"
}

print_warning() {
    printf "${RED}%-30s: %s [FAIL]${NC}\n" "$1" "$2"
}

print_error() {
    printf "${RED}%-30s: %s [FAIL]${NC}\n" "$1" "$2"
}

if [ "$EUID" -ne 0 ]; then 
    echo "Please run this script with sudo: sudo bash $0"
    exit 1
fi

# Maximize the terminal window
maximize_terminal

output_file="macos_qc_report_$(date +%Y%m%d_%H%M%S).txt"

log_output() {
    echo "$1" | tee -a "$output_file"
}

{
echo "════════════════════════════════════════════════════════════════"
echo "                  MacStadium Mac OS QC Report"
echo "════════════════════════════════════════════════════════════════"
echo "Generated: $(date)"
echo "Hostname: $(hostname)"
echo "════════════════════════════════════════════════════════════════"
} > "$output_file"

echo -e "${ORANGE}${BOLD}"
echo "════════════════════════════════════════════════════════════════"
echo "                  MacStadium Mac OS QC Report"
echo "════════════════════════════════════════════════════════════════"
echo -e "${NC}"
echo -e "Started at: ${BOLD}$(date)${NC}"
echo ""

pass_count=0
fail_count=0
test_results=""
failed_tests=""

# HARDWARE
print_header "HARDWARE INFORMATION"
{
echo ""
echo "════════════════════════════════════════════════"
echo "  HARDWARE INFORMATION"
echo "════════════════════════════════════════════════"
} >> "$output_file"

HW=$(system_profiler SPSoftwareDataType SPHardwareDataType 2>/dev/null)

{
echo ""
echo "--- Full Hardware Profile ---"
echo "$HW"
echo "--- End Hardware Profile ---"
echo ""
} >> "$output_file"

mac_os_version=$(echo "$HW" | grep "System Version:" | awk '{print $3, $4, $5, $6}')
print_info "macOS Version" "$mac_os_version"
echo "macOS Version                : $mac_os_version" >> "$output_file"

sip=$(echo "$HW" | grep "System Integrity Protection" | awk '{print $4}')
print_info "SIP Status" "$sip"
echo "SIP Status                   : $sip" >> "$output_file"

model=$(echo "$HW" | grep "Model Number" | awk '{print $3}')
if [ -z "$model" ]; then
    model=$(echo "$HW" | grep "Model Identifier" | awk '{print $3}')
fi
print_info "Model" "$model"
echo "Model                        : $model" >> "$output_file"

chip=$(echo "$HW" | grep "Chip:" | cut -d: -f2 | xargs)
if [ ! -z "$chip" ]; then
    print_info "Chip" "$chip"
    echo "Chip                         : $chip" >> "$output_file"
fi

memory=$(echo "$HW" | grep "Memory:" | head -1 | cut -d: -f2 | xargs)
print_info "Memory" "$memory"
echo "Memory                       : $memory" >> "$output_file"

core=$(echo "$HW" | grep "Total Number of Cores" | awk '{print $5, $6, $7, $8, $9}' | xargs)
print_info "CPU Cores" "$core"
echo "CPU Cores                    : $core" >> "$output_file"

serial=$(echo "$HW" | grep "Serial Number (system)" | awk '{print $4}')
if [ -z "$serial" ]; then
    serial=$(echo "$HW" | grep "Serial Number" | head -1 | awk '{print $4}')
fi
print_info "Serial Number" "$serial"
echo "Serial Number                : $serial" >> "$output_file"

uuid=$(echo "$HW" | grep "Hardware UUID" | cut -d: -f2 | xargs)
print_info "Hardware UUID" "$uuid"
echo "Hardware UUID                : $uuid" >> "$output_file"

disksize=$(diskutil info disk0 2>/dev/null | grep 'Disk Size:' | cut -d: -f2 | xargs)
print_info "Disk Size" "$disksize"
echo "Disk Size                    : $disksize" >> "$output_file"

# POWER MANAGEMENT
print_header "POWER MANAGEMENT SETTINGS"
{
echo ""
echo "════════════════════════════════════════════════"
echo "  POWER MANAGEMENT SETTINGS"
echo "════════════════════════════════════════════════"
} >> "$output_file"

hard_disk_sleep=$(systemsetup -getharddisksleep 2>/dev/null | cut -d: -f2 | xargs)
if [[ "$hard_disk_sleep" == *"Never"* ]]; then
    print_info "Hard Disk Sleep" "$hard_disk_sleep"
    echo "Hard Disk Sleep              : $hard_disk_sleep [PASS]" >> "$output_file"
    ((pass_count++))
else
    print_warning "Hard Disk Sleep" "$hard_disk_sleep (Expected: Never)"
    echo "Hard Disk Sleep              : $hard_disk_sleep [FAIL - Expected: Never]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Hard Disk Sleep: $hard_disk_sleep (Expected: Never)"
fi

display_sleep=$(systemsetup -getdisplaysleep 2>/dev/null | cut -d: -f2 | xargs)
if [[ "$display_sleep" == *"Never"* ]]; then
    print_info "Display Sleep" "$display_sleep"
    echo "Display Sleep                : $display_sleep [PASS]" >> "$output_file"
    ((pass_count++))
else
    print_warning "Display Sleep" "$display_sleep (Expected: Never)"
    echo "Display Sleep                : $display_sleep [FAIL - Expected: Never]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Display Sleep: $display_sleep (Expected: Never)"
fi

computer_sleep=$(systemsetup -getcomputersleep 2>/dev/null | cut -d: -f2 | xargs)
if [[ "$computer_sleep" == *"Never"* ]]; then
    print_info "Computer Sleep" "$computer_sleep"
    echo "Computer Sleep               : $computer_sleep [PASS]" >> "$output_file"
    ((pass_count++))
else
    print_warning "Computer Sleep" "$computer_sleep (Expected: Never)"
    echo "Computer Sleep               : $computer_sleep [FAIL - Expected: Never]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Computer Sleep: $computer_sleep (Expected: Never)"
fi

wake_on_network=$(systemsetup -getwakeonnetworkaccess 2>/dev/null | cut -d: -f2 | xargs)
if [[ "$wake_on_network" == *"On"* ]]; then
    print_info "Wake on Network Access" "$wake_on_network"
    echo "Wake on Network Access       : $wake_on_network [PASS]" >> "$output_file"
    ((pass_count++))
else
    print_warning "Wake on Network Access" "$wake_on_network (Expected: On)"
    echo "Wake on Network Access       : $wake_on_network [FAIL - Expected: On]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Wake on Network Access: $wake_on_network (Expected: On)"
fi

restart_power_fail=$(systemsetup -getrestartpowerfailure 2>/dev/null | cut -d: -f2 | xargs)
if [[ "$restart_power_fail" == *"On"* ]]; then
    print_info "Restart on Power Failure" "$restart_power_fail"
    echo "Restart on Power Failure     : $restart_power_fail [PASS]" >> "$output_file"
    ((pass_count++))
else
    print_warning "Restart on Power Failure" "$restart_power_fail (Expected: On)"
    echo "Restart on Power Failure     : $restart_power_fail [FAIL - Expected: On]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Restart on Power Failure: $restart_power_fail (Expected: On)"
fi

screensaver_time=$(defaults -currentHost read com.apple.screensaver idleTime 2>&1)
if [[ "$screensaver_time" == *"does not exist"* ]] || [[ "$screensaver_time" == "0" ]]; then
    print_info "Screen Saver Start" "Never"
    echo "Screen Saver Start           : Never [PASS]" >> "$output_file"
    ((pass_count++))
elif [[ "$screensaver_time" =~ ^[0-9]+$ ]]; then
    print_warning "Screen Saver Start" "${screensaver_time} seconds (Expected: Never)"
    echo "Screen Saver Start           : ${screensaver_time} seconds [FAIL - Expected: Never]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Screen Saver Start: ${screensaver_time} seconds (Expected: Never)"
else
    print_info "Screen Saver Start" "Never (not configured)"
    echo "Screen Saver Start           : Never (not configured) [PASS]" >> "$output_file"
    ((pass_count++))
fi

display_battery=$(sudo pmset -g | grep "displaysleep" | awk '{print $2}' | head -1)
if [[ "$display_battery" == "0" ]]; then
    print_info "Display Off on Battery" "Never"
    echo "Display Off on Battery      : Never [PASS]" >> "$output_file"
    ((pass_count++))
else
    print_warning "Display Off on Battery" "${display_battery} min (Expected: Never)"
    echo "Display Off on Battery      : ${display_battery} min [FAIL - Expected: Never]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Display Off on Battery: ${display_battery} min (Expected: Never)"
fi

password_required=$(defaults read com.apple.screensaver askForPassword 2>/dev/null)
password_delay=$(defaults read com.apple.screensaver askForPasswordDelay 2>/dev/null)
if [[ "$password_required" == "0" ]]; then
    print_info "Require Password After Sleep" "Never"
    echo "Require Password After Sleep : Never [PASS]" >> "$output_file"
    ((pass_count++))
elif [[ "$password_required" == "1" ]] && [[ "$password_delay" == "0" ]]; then
    print_warning "Require Password After Sleep" "Immediately (Expected: Never)"
    echo "Require Password After Sleep : Immediately [FAIL - Expected: Never]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Require Password After Sleep: Immediately (Expected: Never)"
elif [[ "$password_required" == "1" ]]; then
    print_warning "Require Password After Sleep" "After ${password_delay} seconds (Expected: Never)"
    echo "Require Password After Sleep : After ${password_delay} seconds [FAIL - Expected: Never]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Require Password After Sleep: After ${password_delay} seconds (Expected: Never)"
else
    print_info "Require Password After Sleep" "Not configured"
    echo "Require Password After Sleep : Not configured" >> "$output_file"
fi

# NETWORK
print_header "NETWORK CONFIGURATION"
{
echo ""
echo "════════════════════════════════════════════════"
echo "  NETWORK CONFIGURATION"
echo "════════════════════════════════════════════════"
} >> "$output_file"

hostname=$(hostname)
if [[ "$hostname" == *"administrator"* ]]; then
    print_warning "Hostname" "$hostname (Contains 'administrator')"
    echo "Hostname                     : $hostname [FAIL - Contains 'administrator']" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Hostname: $hostname (Contains 'administrator')"
else
    print_info "Hostname" "$hostname"
    echo "Hostname                     : $hostname [PASS]" >> "$output_file"
    ((pass_count++))
fi

remotelogin=$(systemsetup -getremotelogin 2>/dev/null | cut -d: -f2 | xargs)
if [[ "$remotelogin" == *"On"* ]]; then
    print_info "Remote Login (SSH)" "$remotelogin"
    echo "Remote Login (SSH)           : $remotelogin [PASS]" >> "$output_file"
    ((pass_count++))
else
    print_warning "Remote Login (SSH)" "$remotelogin (Expected: On)"
    echo "Remote Login (SSH)           : $remotelogin [FAIL - Expected: On]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Remote Login (SSH): $remotelogin (Expected: On)"
fi

vnc_enabled=0
vnc_method=""

ard_status=$(sudo defaults read /Library/Preferences/com.apple.RemoteManagement.plist ARD_AllLocalUsers 2>/dev/null)
if [[ "$ard_status" == "1" ]]; then
    vnc_enabled=1
    vnc_method="Remote Management"
fi

if [[ $vnc_enabled -eq 0 ]]; then
    screen_sharing_pid=$(sudo launchctl list | grep com.apple.screensharing 2>/dev/null | awk '{print $1}')
    if [[ "$screen_sharing_pid" != "-" ]] && [[ ! -z "$screen_sharing_pid" ]]; then
        vnc_enabled=1
        vnc_method="Screen Sharing Service"
    fi
fi

if [[ $vnc_enabled -eq 0 ]]; then
    port_check=$(sudo lsof -i :5900 2>/dev/null | grep -c LISTEN)
    if [[ $port_check -gt 0 ]]; then
        vnc_enabled=1
        vnc_method="Port 5900"
    fi
fi

if [[ $vnc_enabled -eq 1 ]]; then
    print_info "Screen Sharing (VNC)" "Enabled via $vnc_method"
    echo "Screen Sharing (VNC)         : Enabled via $vnc_method [PASS]" >> "$output_file"
    ((pass_count++))
else
    print_warning "Screen Sharing (VNC)" "Disabled (Expected: Enabled)"
    echo "Screen Sharing (VNC)         : Disabled [FAIL - Expected: Enabled]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Screen Sharing (VNC): Disabled (Expected: Enabled)"
fi

ethernet_info=$(networksetup -getinfo ethernet 2>/dev/null)
if [ ! -z "$ethernet_info" ]; then
    customer_ip=$(echo "$ethernet_info" | grep "^IP address:" | cut -d: -f2 | xargs)
    subnet_mask=$(echo "$ethernet_info" | grep "Subnet mask:" | cut -d: -f2 | xargs)
    default_gateway=$(echo "$ethernet_info" | grep "^Router:" | awk '{print $2}')
    
    print_info "Ethernet IP Address" "${customer_ip:-Not configured}"
    print_info "Subnet Mask" "${subnet_mask:-Not configured}"
    print_info "Default Gateway" "${default_gateway:-Not configured}"
    
    echo "Ethernet IP Address          : ${customer_ip:-Not configured}" >> "$output_file"
    echo "Subnet Mask                  : ${subnet_mask:-Not configured}" >> "$output_file"
    echo "Default Gateway              : ${default_gateway:-Not configured}" >> "$output_file"
else
    print_warning "Ethernet" "Not configured"
    echo "Ethernet                     : Not configured" >> "$output_file"
fi

DNS=$(networksetup -getdnsservers Ethernet 2>/dev/null)
if [[ -z "$DNS" || "$DNS" == *"There aren't any DNS Servers"* ]]; then
    print_warning "DNS Servers" "Not configured"
    echo "DNS Servers                  : Not configured [FAIL]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - DNS Servers: Not configured"
else
    DNS_formatted=$(echo $DNS | tr '\n' ', ' | sed 's/, $//')
    print_info "DNS Servers" "$DNS_formatted"
    echo "DNS Servers                  : $DNS_formatted [PASS]" >> "$output_file"
    ((pass_count++))
fi

# SECURITY
print_header "SECURITY SETTINGS"
{
echo ""
echo "════════════════════════════════════════════════"
echo "  SECURITY SETTINGS"
echo "════════════════════════════════════════════════"
} >> "$output_file"

firewall_status=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>&1)
if [[ "$firewall_status" == *"does not exist"* ]] || [[ -z "$firewall_status" ]]; then
    print_info "Firewall" "Disabled (not configured)"
    echo "Firewall                     : Disabled (not configured) [PASS]" >> "$output_file"
    ((pass_count++))
elif [[ "$firewall_status" == "0" ]]; then
    print_info "Firewall" "Disabled"
    echo "Firewall                     : Disabled [PASS]" >> "$output_file"
    ((pass_count++))
elif [[ "$firewall_status" == "1" ]]; then
    print_warning "Firewall" "Enabled (Expected: Disabled)"
    echo "Firewall                     : Enabled [FAIL - Expected: Disabled]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Firewall: Enabled (Expected: Disabled)"
elif [[ "$firewall_status" == "2" ]]; then
    print_warning "Firewall" "Enabled with stealth mode (Expected: Disabled)"
    echo "Firewall                     : Enabled with stealth mode [FAIL - Expected: Disabled]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Firewall: Enabled with stealth mode (Expected: Disabled)"
else
    print_info "Firewall" "Unknown status: $firewall_status"
    echo "Firewall                     : Unknown status: $firewall_status" >> "$output_file"
fi

# WIRELESS & BLUETOOTH
print_header "WIRELESS & BLUETOOTH SETTINGS"
{
echo ""
echo "════════════════════════════════════════════════"
echo "  WIRELESS & BLUETOOTH SETTINGS"
echo "════════════════════════════════════════════════"
} >> "$output_file"

wifi_service_name=$(networksetup -listallnetworkservices 2>/dev/null | grep -E "Wi-Fi|AirPort|Wireless" | head -1)
if [ ! -z "$wifi_service_name" ]; then
    wifi_enabled=$(networksetup -getnetworkserviceenabled "$wifi_service_name" 2>/dev/null)
    if [[ "$wifi_enabled" == *"Disabled"* ]]; then
        print_info "Wi-Fi Service ($wifi_service_name)" "Disabled"
        echo "Wi-Fi Service                : Disabled [PASS]" >> "$output_file"
        ((pass_count++))
    elif [[ "$wifi_enabled" == *"Enabled"* ]]; then
        print_warning "Wi-Fi Service ($wifi_service_name)" "Enabled (Expected: Disabled)"
        echo "Wi-Fi Service                : Enabled [FAIL - Expected: Disabled]" >> "$output_file"
        ((fail_count++))
        failed_tests+="\n  - Wi-Fi Service: Enabled (Expected: Disabled)"
    else
        print_info "Wi-Fi Service" "Status unknown: $wifi_enabled"
        echo "Wi-Fi Service                : $wifi_enabled" >> "$output_file"
    fi
else
    print_info "Wi-Fi Service" "Not found (No Wi-Fi hardware)"
    echo "Wi-Fi Service                : Not found (No Wi-Fi hardware) [PASS]" >> "$output_file"
    ((pass_count++))
fi

wifi_interface=$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi|AirPort|Wireless/{getline; print $2}')
if [ ! -z "$wifi_interface" ]; then
    preferred_networks=$(networksetup -listpreferredwirelessnetworks "$wifi_interface" 2>/dev/null)
    if [[ "$preferred_networks" == *"is not a Wi-Fi interface"* ]] || [ -z "$preferred_networks" ]; then
        print_info "Preferred Wi-Fi Networks" "No Wi-Fi interface"
        echo "Preferred Wi-Fi Networks     : No Wi-Fi interface [PASS]" >> "$output_file"
        ((pass_count++))
    else
        network_count=$(echo "$preferred_networks" | grep -v "Preferred networks" | wc -l | xargs)
        if [[ $network_count -eq 0 ]]; then
            print_info "Preferred Wi-Fi Networks" "None configured"
            echo "Preferred Wi-Fi Networks     : None configured [PASS]" >> "$output_file"
            ((pass_count++))
        else
            print_warning "Preferred Wi-Fi Networks" "$network_count network(s) found (Should be empty)"
            echo "Preferred Wi-Fi Networks     : $network_count network(s) found [FAIL - Should be empty]" >> "$output_file"
            ((fail_count++))
            failed_tests+="\n  - Preferred Wi-Fi Networks: $network_count network(s) found (Should be empty)"
        fi
    fi
else
    print_info "Preferred Wi-Fi Networks" "No Wi-Fi hardware detected"
    echo "Preferred Wi-Fi Networks     : No Wi-Fi hardware detected [PASS]" >> "$output_file"
    ((pass_count++))
fi

wifi_icon=$(defaults read com.apple.controlcenter "NSStatusItem Visible WiFi" 2>/dev/null)
if [ ! -z "$wifi_icon" ]; then
    if [[ "$wifi_icon" == "0" ]]; then
        print_info "Wi-Fi Menu Bar Icon" "Hidden"
        echo "Wi-Fi Menu Bar Icon          : Hidden" >> "$output_file"
    else
        print_info "Wi-Fi Menu Bar Icon" "Visible"
        echo "Wi-Fi Menu Bar Icon          : Visible" >> "$output_file"
    fi
else
    print_info "Wi-Fi Menu Bar Icon" "Not configured"
    echo "Wi-Fi Menu Bar Icon          : Not configured" >> "$output_file"
fi

bluetooth_info=$(system_profiler SPBluetoothDataType 2>/dev/null)
bluetooth_power=$(echo "$bluetooth_info" | grep -E "Bluetooth Power:" | head -1 | cut -d: -f2 | xargs)
if [[ "$bluetooth_power" == "Off" ]]; then
    print_info "Bluetooth State" "Off"
    echo "Bluetooth State              : Off [PASS]" >> "$output_file"
    ((pass_count++))
else
    print_warning "Bluetooth State" "$bluetooth_power (Expected: Off)"
    echo "Bluetooth State              : $bluetooth_power [FAIL - Expected: Off]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Bluetooth State: $bluetooth_power (Expected: Off)"
fi

bluetooth_discoverable=$(echo "$bluetooth_info" | grep "Discoverable:" | head -1 | cut -d: -f2 | xargs)
if [[ "$bluetooth_discoverable" == "Off" ]]; then
    print_info "Bluetooth Discoverable" "Off"
    echo "Bluetooth Discoverable       : Off [PASS]" >> "$output_file"
    ((pass_count++))
else
    print_warning "Bluetooth Discoverable" "$bluetooth_discoverable (Expected: Off)"
    echo "Bluetooth Discoverable       : $bluetooth_discoverable [FAIL - Expected: Off]" >> "$output_file"
    ((fail_count++))
    failed_tests+="\n  - Bluetooth Discoverable: $bluetooth_discoverable (Expected: Off)"
fi

# SUMMARY
print_header "QC SUMMARY"
{
echo ""
echo "════════════════════════════════════════════════"
echo "  QC SUMMARY"
echo "════════════════════════════════════════════════"
} >> "$output_file"

echo ""
echo -e "${BOLD}System Information:${NC}"
echo -e "  Hostname                : ${CYAN}$hostname${NC}"
echo -e "  System Version          : ${CYAN}$mac_os_version${NC}"
echo -e "  Model Identifier        : ${CYAN}$model${NC}"
if [ ! -z "$chip" ]; then
    echo -e "  Chip Model              : ${CYAN}$chip${NC}"
fi
echo -e "  Serial Number           : ${CYAN}$serial${NC}"
echo -e "  Total Number of Cores   : ${CYAN}$core${NC}"
echo -e "  Memory                  : ${CYAN}$memory${NC}"
echo -e "  Disk Size               : ${CYAN}$disksize${NC}"

echo ""
echo -e "${BOLD}Network Configuration:${NC}"
echo -e "  Ethernet IP Address     : ${CYAN}${customer_ip:-Not configured}${NC}"
echo -e "  Subnet Mask             : ${CYAN}${subnet_mask:-Not configured}${NC}"
echo -e "  Default Gateway         : ${CYAN}${default_gateway:-Not configured}${NC}"
echo -e "  DNS Servers             : ${CYAN}${DNS_formatted:-Not configured}${NC}"

{
echo ""
echo "System Information:"
echo "  Hostname                : $hostname"
echo "  System Version          : $mac_os_version"
echo "  Model Identifier        : $model"
if [ ! -z "$chip" ]; then
    echo "  Chip Model              : $chip"
fi
echo "  Serial Number           : $serial"
echo "  Total Number of Cores   : $core"
echo "  Memory                  : $memory"
echo "  Disk Size               : $disksize"
echo ""
echo "Network Configuration:"
echo "  Ethernet IP Address     : ${customer_ip:-Not configured}"
echo "  Subnet Mask             : ${subnet_mask:-Not configured}"
echo "  Default Gateway         : ${default_gateway:-Not configured}"
echo "  DNS Servers             : ${DNS_formatted:-Not configured}"
} >> "$output_file"

if [[ $fail_count -gt 0 ]]; then
    echo ""
    echo -e "${RED}${BOLD}Failed Tests:${NC}"
    echo -e "${RED}$failed_tests${NC}"
    {
    echo ""
    echo "Failed Tests:"
    echo -e "$failed_tests"
    } >> "$output_file"
else
    echo ""
    echo -e "${GREEN}${BOLD}All tests passed!${NC}"
    {
    echo ""
    echo "All tests passed!"
    } >> "$output_file"
fi

{
echo ""
echo "════════════════════════════════════════════════"
echo "Report completed at: $(date)"
echo "════════════════════════════════════════════════"
} >> "$output_file"

echo ""
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}✓ Report saved to: $output_file${NC}"
echo -e "${CYAN}${BOLD}════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BOLD}Quality check completed at: $(date)${NC}"
