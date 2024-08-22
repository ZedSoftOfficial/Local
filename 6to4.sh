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

    # Ensure the file exists and is executable
    if [ ! -f "$FILE" ]; then
        echo -e '#! /bin/bash\n\nexit 0' | sudo tee "$FILE" > /dev/null
        sudo chmod +x "$FILE"
    fi

    # Clear the file and add new commands
    sudo bash -c "echo -e '#! /bin/bash\n\n$commands\n\nexit 0' > $FILE"

    echo "Commands added to /etc/rc.local and the file has been reset."
}

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
        eval "$commands"
        echo "Commands executed for the outside server."

    elif [ "$six_to_four_choice" -eq 2 ]; then
        read -p "Enter the IP Iran: " ipiran
        read -p "Enter the IP outside: " ipkharej
        read -p "Do you want all ports to be tunneled? (yes/no): " tunnel_all

        if [ "$tunnel_all" == "yes" ]; then
            iptables_cmds=$(cat <<EOF
sysctl net.ipv4.ip_forward=1
iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 10.10.10.1
iptables -t nat -A PREROUTING -j DNAT --to-destination 10.10.10.2
iptables -t nat -A POSTROUTING -j MASQUERADE
EOF
)
        else
            read -p "Which ports to tunnel? (comma-separated, e.g., 800,8080,6060): " ports
            iptables_cmds=$(cat <<EOF
sysctl net.ipv4.ip_forward=1
iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 10.10.10.1
EOF
)

            IFS=',' read -ra ADDR <<< "$ports"
            for port in "${ADDR[@]}"; do
                iptables_cmds+="iptables -t nat -A PREROUTING -p tcp --dport $port -j DNAT --to-destination 10.10.10.2\n"
            done
            iptables_cmds+="iptables -t nat -A POSTROUTING -j MASQUERADE"
        fi

        commands=$(cat <<EOF
ip tunnel add 6to4_To_KH mode sit remote $ipkharej local $ipiran
ip -6 addr add 2002:480:1f10:e1f::1/64 dev 6to4_To_KH
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up

ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote 2002:480:1f10:e1f::2 local 2002:480:1f10:e1f::1
ip addr add 10.10.10.1/30 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up

$iptables_cmds
EOF
)

        setup_rc_local "$commands"
        eval "$commands"
        echo "Commands executed for the Iran server."

    else
        echo "Invalid option. Please select 1 or 2."
    fi
}

# Other functions (Remove tunnels, BBR, etc.) remain unchanged

# Execute the selected option
case $server_choice in
    1)
        handle_six_to_four
        ;;
    2)
        # Code for removing tunnels (remains unchanged)
        ;;
    3)
        # Code for enabling BBR (remains unchanged)
        ;;
    4)
        # Code for fixing WhatsApp time (remains unchanged)
        ;;
    5)
        # Code for optimizing (remains unchanged)
        ;;
    6)
        # Code for installing x-ui (remains unchanged)
        ;;
    7)
        # Code for changing NameServer (remains unchanged)
        ;;
    8)
        # Code for disabling IPv6 (remains unchanged)
        ;;
    *)
        echo "Invalid option. Please select 1, 2, 3, 4, 5, 6, 7, or 8."
        ;;
esac
