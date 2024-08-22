#!/bin/bash

echo "What should I do?"
echo "1) 6to4"
echo "2) Remove tunnels"
echo "3) Enable BBR"
echo "4) Fix Whatsapp Time"
echo "5) Optimize"
echo "6) Install x-ui"
echo "7) Change NameServer"
echo "8) Disable IPv6 - After server reboot IPv6 is activated"
read -p "Select an option (1, 2, 3, 4, 5, 6, 7, or 8): " server_choice

setup_rc_local() {
    FILE="/etc/rc.local"
    commands="$1"

    # Ensure the file exists and is executable, or empty it if it already exists
    if [ -f "$FILE" ]; then
        sudo bash -c "echo -e '#! /bin/bash\n\nexit 0' > $FILE"
    else
        echo -e '#! /bin/bash\n\nexit 0' | sudo tee "$FILE" > /dev/null
    fi
    sudo chmod +x "$FILE"

    # Add new commands above 'exit 0'
    sudo bash -c "sed -i '/exit 0/i $commands' $FILE"
    echo "Commands added to /etc/rc.local"

    # Execute the commands immediately
    eval "$commands"
    echo "Commands executed immediately."
}

# Function to handle Fix Whatsapp Time option
fix_whatsapp_time() {
    commands="sudo timedatectl set-timezone Asia/Tehran"
    setup_rc_local "$commands"
    echo "Whatsapp time fixed to Asia/Tehran timezone."
}

# Function to handle Optimize option
optimize() {
    USER_CONF="/etc/systemd/user.conf"
    SYSTEM_CONF="/etc/systemd/system.conf"
    LIMITS_CONF="/etc/security/limits.conf"
    SYSCTL_CONF="/etc/sysctl.d/local.conf"
    TEMP_USER_CONF=$(mktemp)
    TEMP_SYSTEM_CONF=$(mktemp)

    # Function to add line if not exists
    add_line_if_not_exists() {
        local file="$1"
        local line="$2"
        local temp_file="$3"

        if [ -f "$file" ];then
            cp "$file" "$temp_file"
            if ! grep -q "$line" "$file"; then
                sed -i '/^\[Manager\]/a '"$line" "$temp_file"
                sudo mv "$temp_file" "$file"
                echo "Added '$line' to $file"
            else
                echo "The line '$line' already exists in $file"
                rm "$temp_file"
            fi
        else
            echo "$file does not exist."
            rm "$temp_file"
        fi
    }

    # Optimize user.conf
    add_line_if_not_exists "$USER_CONF" "DefaultLimitNOFILE=1024000" "$TEMP_USER_CONF"

    # Optimize system.conf
    add_line_if_not_exists "$SYSTEM_CONF" "DefaultLimitNOFILE=1024000" "$TEMP_SYSTEM_CONF"

    # Optimize limits.conf
    if [ -f "$LIMITS_CONF" ];then
        cat <<EOF | sudo tee -a "$LIMITS_CONF"
* hard nofile 1024000
* soft nofile 1024000
root hard nofile 1024000
root soft nofile 1024000
EOF
        echo "Added limits to $LIMITS_CONF"
    else
        echo "$LIMITS_CONF does not exist."
    fi

    # Optimize sysctl.d/local.conf
    cat <<EOF | sudo tee "$SYSCTL_CONF"
# max open files
fs.file-max = 1024000
EOF
    echo "Added sysctl settings to $SYSCTL_CONF"

    # Apply sysctl changes
    sudo sysctl --system
    echo "Sysctl changes applied."
}

# Function to install x-ui
install_x_ui() {
    echo "Choose the version of x-ui to install:"
    echo "1) alireza"
    echo "2) MHSanaei"
    read -p "Select an option (1 or 2): " xui_choice

    if [ "$xui_choice" -eq 1 ]; then
        bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
        echo "alireza version of x-ui installed."
    elif [ "$xui_choice" -eq 2 ]; then
        bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
        echo "MHSanaei version of x-ui installed."
    else
        echo "Invalid option. Please select 1 or 2."
    fi
}

# Function to disable IPv6
disable_ipv6() {
    commands=$(cat <<EOF
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
EOF
)

    setup_rc_local "$commands"
    echo "IPv6 has been disabled."
}

# Function to handle 6to4 option
handle_six_to_four() {
    echo "Choose the type of server:"
    echo "1) Outside"
    echo "2) Iran"
    read -p "Select an option (1 or 2): " six_to_four_choice

    if [ "$six_to_four_choice" -eq 1 ]; then
        read -p "Enter the IP outside: " ipkharej
        read -p "Enter the IP Iran: " ipiran

        commands=$(cat <<EOF
ip tunnel add 6to4_To_IR mode sit remote $ipiran local $ipkharej
ip -6 addr add 2002:480:1f10:e1f::2/64 dev 6to4_To_IR
ip link set 6to4_To_IR mtu 1480
ip link set 6to4_To_IR up

ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote 2002:480:1f10:e1f::1 local 2002:480:1f10:e1f::2
ip addr add 10.10.10.2/30 dev GRE6Tun_To_IR
ip link set GRE6Tun_To_IR mtu 1436
ip link set GRE6Tun_To_IR up
EOF
)

        setup_rc_local "$commands"
        echo "Commands executed for the outside server."

    elif [ "$six_to_four_choice" -eq 2 ]; then
        read -p "Enter the IP Iran: " ipiran
        read -p "Enter the IP outside: " ipkharej

        commands=$(cat <<EOF
ip tunnel add 6to4_To_KH mode sit remote $ipkharej local $ipiran
ip -6 addr add 2002:480:1f10:e1f::1/64 dev 6to4_To_KH
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up

ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote 2002:480:1f10:e1f::2 local 2002:480:1f10:e1f::1
ip addr add 10.10.10.1/30 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up

sysctl net.ipv4.ip_forward=1
iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 10.10.10.1
iptables -t nat -A PREROUTING -j DNAT --to-destination 10.10.10.2
iptables -t nat -A POSTROUTING -j MASQUERADE
EOF
)

        setup_rc_local "$commands"
        echo "Commands executed for the Iran server."

    else
        echo "Invalid option. Please select 1 or 2."
    fi
}

# Function to change NameServer
change_nameserver() {
    FILE="/etc/resolv.conf"
    if [ -f "$FILE" ]; then
        # Backup the original file
        sudo cp "$FILE" "${FILE}.bak"

        # Remove existing nameserver lines
        sudo sed -i '/^nameserver /d' "$FILE"

        # Add new nameserver lines
        echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" | sudo tee -a "$FILE" > /dev/null

        echo "NameServers have been updated."
    else
        echo "$FILE does not exist."
    fi
}

# Execute the selected option
case $server_choice in
    1)
        handle_six_to_four
        ;;
    2)
        echo "Removing tunnels..."
        ip tunnel del 6to4_To_IR 2>/dev/null
        ip -6 tunnel del GRE6Tun_To_IR 2>/dev/null
        ip link del 6to4_To_IR 2>/dev/null
        ip link del GRE6Tun_To_IR 2>/dev/null
        iptables -t nat -D PREROUTING -j DNAT --to-destination 10.10.10.2 2>/dev/null
        iptables -t nat -D POSTROUTING -j MASQUERADE 2>/dev/null
        echo -e '#! /bin/bash\n\nexit 0' | sudo tee /etc/rc.local > /dev/null
        sudo chmod +x /etc/rc.local
        echo "Tunnels removed. /etc/rc.local is empty now."
        ;;
    3)
        wget --no-check-certificate -O /opt/bbr.sh https://github.com/teddysun/across/raw/master/bbr.sh
        chmod 755 /opt/bbr.sh
        /opt/bbr.sh
        echo "BBR optimization enabled."
        ;;
    4)
        fix_whatsapp_time
        ;;
    5)
        optimize
        ;;
    6)
        install_x_ui
        ;;
    7)
        change_nameserver
        ;;
    8)
        disable_ipv6
        ;;
    *)
        echo "Invalid option. Please select 1, 2, 3, 4, 5, 6, 7, or 8."
        ;;
esac
