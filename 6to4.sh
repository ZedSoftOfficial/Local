#!/bin/bash

echo "What should I do?"
echo "1) 6to4"
echo "2) 6to4 multi server (1 Iran 2 outside)"
echo "3) 6to4 multi server (1 outside 2 Iran)"
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
    echo "Which server is this?"
    echo "1) Outside"
    echo "2) Iran1"
    echo "3) Iran2"
    read -p "Select an option (1, 2, or 3): " server_role

    case $server_role in
        1)
            read -p "Enter the IP Outside: " ipkharej
            read -p "Enter the IP Iran1: " ipiran1
            read -p "Enter the IP Iran2: " ipiran2

            commands=$(cat <<EOF
ip tunnel add 6to4_To_IR1 mode sit remote $ipiran1 local $ipkharej
ip -6 addr add 2002:480:1f10:e1f::2/64 dev 6to4_To_IR1
ip link set 6to4_To_IR1 mtu 1480
ip link set 6to4_To_IR1 up

ip -6 tunnel add GRE6Tun_To_IR1 mode ip6gre remote 2002:480:1f10:e1f::1 local 2002:480:1f10:e1f::2
ip addr add 10.10.10.2/30 dev GRE6Tun_To_IR1
ip link set GRE6Tun_To_IR1 mtu 1436
ip link set GRE6Tun_To_IR1 up

ip tunnel add 6to4_To_IR2 mode sit remote $ipiran2 local $ipkharej
ip -6 addr add 2009:480:1f10:e1f::2/64 dev 6to4_To_IR2
ip link set 6to4_To_IR2 mtu 1480
ip link set 6to4_To_IR2 up

ip -6 tunnel add GRE6Tun_To_IR2 mode ip6gre remote 2009:480:1f10:e1f::1 local 2009:480:1f10:e1f::2
ip addr add 10.10.11.2/30 dev GRE6Tun_To_IR2
ip link set GRE6Tun_To_IR2 mtu 1436
ip link set GRE6Tun_To_IR2 up
EOF
)
            ;;
        2)
            read -p "Enter the IP Iran1: " ipiran1
            read -p "Enter the IP Outside: " ipkharej
            read -p "Enter the ports to tunnel (example: 80,9090): " ports

            commands=$(cat <<EOF
ip tunnel add 6to4_To_KH mode sit remote $ipkharej local $ipiran1
ip -6 addr add 2002:480:1f10:e1f::1/64 dev 6to4_To_KH
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up

ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote 2002:480:1f10:e1f::2 local 2002:480:1f10:e1f::1
ip addr add 10.10.10.1/30 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up

sysctl net.ipv4.ip_forward=1

EOF
)

            # Add iptables rules
            IFS=',' read -r -a ports_array <<< "$ports"
            for port in "${ports_array[@]}"; do
                commands+=$(cat <<EOF
iptables -t nat -A PREROUTING -p tcp --dport $port -j DNAT --to-destination 10.10.10.1
EOF
)
            done
            commands+=$(cat <<EOF
iptables -t nat -A POSTROUTING -j MASQUERADE
EOF
)

            ;;
        3)
            read -p "Enter the IP Iran2: " ipiran2
            read -p "Enter the IP Outside: " ipkharej
            read -p "Enter the ports to tunnel (example: 80,9090): " ports

            commands=$(cat <<EOF
ip tunnel add 6to4_To_KH mode sit remote $ipkharej local $ipiran2
ip -6 addr add 2009:480:1f10:e1f::1/64 dev 6to4_To_KH
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up

ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote 2009:480:1f10:e1f::2 local 2009:480:1f10:e1f::1
ip addr add 10.10.11.1/30 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up

sysctl net.ipv4.ip_forward=1

EOF
)

            # Add iptables rules
            IFS=',' read -r -a ports_array <<< "$ports"
            for port in "${ports_array[@]}"; do
                commands+=$(cat <<EOF
iptables -t nat -A PREROUTING -p tcp --dport $port -j DNAT --to-destination 10.10.11.1
EOF
)
            done
            commands+=$(cat <<EOF
iptables -t nat -A POSTROUTING -j MASQUERADE
EOF
)

            ;;
        *)
            echo "Invalid option. Please select 1, 2, or 3."
            return
            ;;
    esac

    setup_rc_local "$commands"
    echo "Commands executed for the selected server configuration."
}

# Function to remove tunnels
remove_tunnels() {
    echo "Removing tunnels..."

    # Remove the tunnels
    sudo ip tunnel del 6to4_To_IR1 2>/dev/null
    sudo ip tunnel del GRE6Tun_To_IR1 2>/dev/null
    sudo ip tunnel del 6to4_To_IR2 2>/dev/null
    sudo ip tunnel del GRE6Tun_To_IR2 2>/dev/null
    sudo ip link del 6to4_To_KH 2>/dev/null
    sudo ip link del GRE6Tun_To_KH 2>/dev/null
    sudo iptables -t nat -D PREROUTING -j DNAT --to-destination 10.10.10.1 2>/dev/null
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
    echo "Whatsapp time fixed."
}

# Function to enable BBR
enable_bbr() {
    commands=$(cat <<EOF
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr
sudo sysctl -w net.ipv4.tcp_bbr=1
EOF
)
    setup_rc_local "$commands"
    echo "BBR enabled."
}

# Function to install x-ui
install_x_ui() {
    commands=$(cat <<EOF
# Insert installation commands here
EOF
)
    setup_rc_local "$commands"
    echo "x-ui installed."
}

# Function to change nameserver
change_nameserver() {
    commands=$(cat <<EOF
# Insert nameserver change commands here
EOF
)
    setup_rc_local "$commands"
    echo "Nameserver changed."
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
        # Implement handle_six_to_four_multi_iran_kharej function if needed
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
