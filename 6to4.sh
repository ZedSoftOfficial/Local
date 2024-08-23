#!/bin/bash

echo "What should I do?"
echo "1) 6to4"
echo "2) 6to4 multi server (1 iran 2 outside)"
echo "3) 6to4 multi server (1 outside 2 iran)"
echo "4) Remove tunnels"
echo "5) Enable BBR"
echo "6) Fix Whatsapp Time"
echo "7) Optimize"
echo "8) Install x-ui"
echo "9) Change NameServer"
echo "10) Disable IPv6 - After server reboot IPv6 is activated"
read -p "Select an option (1, 2, 3, 4, 5, 6, 7, 8, 9, or 10): " server_choice

setup_rc_local() {
    FILE="/etc/rc.local"
    commands="$1"

    # Ensure the file exists and is executable, or create and set it
    if [ ! -f "$FILE" ]; then
        echo -e '#! /bin/bash\n\nexit 0' | sudo tee "$FILE" > /dev/null
    fi
    sudo chmod +x "$FILE"

    # Add new commands before 'exit 0'
    sudo bash -c "sed -i '/exit 0/i $commands' $FILE"
    echo "Commands added to /etc/rc.local"

    # Execute the commands immediately
    eval "$commands"
    echo "Commands executed immediately."
}

# Function to handle 6to4 multi server (1 outside 2 iran)
handle_six_to_four_multi_outside_iran() {
    read -p "Enter the IP outside1: " ipkharej1
    read -p "Enter the IP outside2: " ipkharej2
    read -p "Enter the IP Iran: " ipiran
    read -p "Enter the ports to tunnel for IP outside1 (example: 80,9090): " ports_outside1
    read -p "Enter the ports to tunnel for IP outside2 (example: 80,9090): " ports_outside2

    # Convert comma-separated ports into individual rules
    IFS=',' read -r -a ports_outside1_array <<< "$ports_outside1"
    IFS=',' read -r -a ports_outside2_array <<< "$ports_outside2"

    commands=""

    for port in "${ports_outside1_array[@]}"; do
        commands+=$(cat <<EOF
iptables -t nat -A PREROUTING -p tcp -d $ipkharej1 --dport $port -j DNAT --to-destination 10.10.10.1
EOF
)
    done

    for port in "${ports_outside2_array[@]}"; do
        commands+=$(cat <<EOF
iptables -t nat -A PREROUTING -p tcp -d $ipkharej2 --dport $port -j DNAT --to-destination 10.10.10.2
EOF
)
    done

    commands+=$(cat <<EOF
sysctl net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -j MASQUERADE
EOF
)

    setup_rc_local "$commands"
    echo "Commands executed for the multi-server (1 Outside, 2 Iran) setup."
}

# Function to handle 6to4 multi server (1 iran 2 outside)
handle_six_to_four_multi_iran_kharej() {
    read -p "Enter the IP Iran: " ipiran
    read -p "Enter the IP outside1: " ipkharej1
    read -p "Enter the IP outside2: " ipkharej2
    read -p "Enter the ports to tunnel for IP Iran (example: 80,9090): " ports_iran
    read -p "Enter the ports to tunnel for IP outside1 (example: 80,9090): " ports_outside1
    read -p "Enter the ports to tunnel for IP outside2 (example: 80,9090): " ports_outside2

    # Convert comma-separated ports into individual rules
    IFS=',' read -r -a ports_iran_array <<< "$ports_iran"
    IFS=',' read -r -a ports_outside1_array <<< "$ports_outside1"
    IFS=',' read -r -a ports_outside2_array <<< "$ports_outside2"

    commands=""

    for port in "${ports_iran_array[@]}"; do
        commands+=$(cat <<EOF
iptables -t nat -A PREROUTING -p tcp -d $ipiran --dport $port -j DNAT --to-destination 10.10.10.1
EOF
)
    done

    for port in "${ports_outside1_array[@]}"; do
        commands+=$(cat <<EOF
iptables -t nat -A PREROUTING -p tcp -d $ipkharej1 --dport $port -j DNAT --to-destination 10.10.10.2
EOF
)
    done

    for port in "${ports_outside2_array[@]}"; do
        commands+=$(cat <<EOF
iptables -t nat -A PREROUTING -p tcp -d $ipkharej2 --dport $port -j DNAT --to-destination 10.10.10.3
EOF
)
    done

    commands+=$(cat <<EOF
sysctl net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -j MASQUERADE
EOF
)

    setup_rc_local "$commands"
    echo "Commands executed for the multi-server (1 Iran, 2 Outside) setup."
}

# Function to remove tunnels
remove_tunnels() {
    echo "Removing tunnels..."

    # Remove the tunnels
    sudo ip tunnel del 6to4_To_IR 2>/dev/null
    sudo ip -6 tunnel del GRE6Tun_To_IR 2>/dev/null
    sudo ip link del 6to4_To_IR 2>/dev/null
    sudo ip link del GRE6Tun_To_IR 2>/dev/null
    sudo iptables -t nat -D PREROUTING -j DNAT --to-destination 10.10.10.2 2>/dev/null
    sudo iptables -t nat -D POSTROUTING -j MASQUERADE 2>/dev/null

    # Update /etc/rc.local
    echo -e '#! /bin/bash\n\nexit 0' | sudo tee /etc/rc.local > /dev/null
    sudo chmod +x /etc/rc.local

    echo "Tunnels removed and /etc/rc.local updated."
}

# Function to fix Whatsapp time
fix_whatsapp_time() {
    commands="sudo timedatectl set-timezone Asia/Tehran"
    setup_rc_local "$commands"
    echo "Whatsapp time fixed to Asia/Tehran timezone."
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

# Function to enable BBR
enable_bbr() {
    commands=$(cat <<EOF
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr
EOF
)
    setup_rc_local "$commands"
    echo "BBR enabled."
}

# Function to change nameserver
change_nameserver() {
    read -p "Enter the new nameserver IP address: " nameserver
    echo "nameserver $nameserver" | sudo tee /etc/resolv.conf > /dev/null
    echo "Nameserver changed to $nameserver."
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
    echo "IPv6 disabled."
}

# Function to optimize settings
optimize() {
    commands=$(cat <<EOF
sudo sysctl -w net.core.somaxconn=1024
sudo sysctl -w net.ipv4.tcp_max_syn_backlog=2048
EOF
)
    setup_rc_local "$commands"
    echo "System optimized."
}

# Execute the selected option
case $server_choice in
    1)
        echo "Handling 6to4..."
        ;;
    2)
        handle_six_to_four_multi_iran_kharej
        ;;
    3)
        handle_six_to_four_multi_outside_iran
        ;;
    4)
        remove_tunnels
        ;;
    5)
        enable_bbr
        ;;
    6)
        fix_whatsapp_time
        ;;
    7)
        optimize
        ;;
    8)
        install_x_ui
        ;;
    9)
        change_nameserver
        ;;
    10)
        disable_ipv6
        ;;
    *)
        echo "Invalid option. Please select 1, 2, 3, 4, 5, 6, 7, 8, 9, or 10."
        ;;
esac
