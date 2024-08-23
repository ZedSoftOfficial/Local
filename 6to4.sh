#!/bin/bash

# Function to handle 6to4 configuration
handle_six_to_four() {
    echo "Setting up 6to4..."
    # Add your 6to4 configuration commands here
}

# Function to handle 6to4 multi-server (1 Iran 2 outside)
handle_six_to_four_multi_iran_kharej() {
    echo "Which server is this?"
    echo "1) Iran1"
    echo "2) Iran2"
    read -p "Select an option (1 or 2): " server_role

    case $server_role in
        1)
            read -p "Enter the IP Iran1: " ipiran1
            read -p "Enter the IP Outside: " ipkharej

            # Commands for Iran1
            commands=$(cat <<EOF
#!/bin/bash

# تنظیمات تونل برای اولین سرور ایران
ip tunnel add 6to4_To_IR1 mode sit remote $ipiran1 local $ipkharej
ip -6 addr add 2002:480:1f10:e1f::2/64 dev 6to4_To_IR1
ip link set 6to4_To_IR1 mtu 1480
ip link set 6to4_To_IR1 up

ip -6 tunnel add GRE6Tun_To_IR1 mode ip6gre remote 2002:480:1f10:e1f::1 local 2002:480:1f10:e1f::2
ip addr add 10.10.10.2/30 dev GRE6Tun_To_IR1
ip link set GRE6Tun_To_IR1 mtu 1436
ip link set GRE6Tun_To_IR1 up

# تنظیمات تونل برای دومین سرور ایران
ip tunnel add 6to4_To_IR2 mode sit remote $ipiran2 local $ipkharej
ip -6 addr add 2009:480:1f10:e1f::2/64 dev 6to4_To_IR2
ip link set 6to4_To_IR2 mtu 1480
ip link set 6to4_To_IR2 up

ip -6 tunnel add GRE6Tun_To_IR2 mode ip6gre remote 2009:480:1f10:e1f::1 local 2009:480:1f10:e1f::2
ip addr add 10.10.11.2/30 dev GRE6Tun_To_IR2
ip link set GRE6Tun_To_IR2 mtu 1436
ip link set GRE6Tun_To_IR2 up

exit 0
EOF
)

            # Write commands to /etc/rc.local
            sudo bash -c "echo '#!/bin/bash' > /etc/rc.local"
            sudo bash -c "echo '$commands' >> /etc/rc.local"
            sudo chmod +x /etc/rc.local
            echo "Commands for 6to4 multi server (1 Iran 2 outside) have been set."
            ;;
        *)
            echo "Invalid option. Please select 1 or 2."
            return
            ;;
    esac
}

# Function to handle 6to4 multi-server (1 outside 2 Iran)
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

            # Commands for Outside server
            commands=$(cat <<EOF
#!/bin/bash

# تنظیمات تونل برای اولین سرور ایران
ip tunnel add 6to4_To_IR1 mode sit remote $ipiran1 local $ipkharej
ip -6 addr add 2002:480:1f10:e1f::2/64 dev 6to4_To_IR1
ip link set 6to4_To_IR1 mtu 1480
ip link set 6to4_To_IR1 up

ip -6 tunnel add GRE6Tun_To_IR1 mode ip6gre remote 2002:480:1f10:e1f::1 local 2002:480:1f10:e1f::2
ip addr add 10.10.10.2/30 dev GRE6Tun_To_IR1
ip link set GRE6Tun_To_IR1 mtu 1436
ip link set GRE6Tun_To_IR1 up

# تنظیمات تونل برای دومین سرور ایران
ip tunnel add 6to4_To_IR2 mode sit remote $ipiran2 local $ipkharej
ip -6 addr add 2009:480:1f10:e1f::2/64 dev 6to4_To_IR2
ip link set 6to4_To_IR2 mtu 1480
ip link set 6to4_To_IR2 up

ip -6 tunnel add GRE6Tun_To_IR2 mode ip6gre remote 2009:480:1f10:e1f::1 local 2009:480:1f10:e1f::2
ip addr add 10.10.11.2/30 dev GRE6Tun_To_IR2
ip link set GRE6Tun_To_IR2 mtu 1436
ip link set GRE6Tun_To_IR2 up

exit 0
EOF
)

            # Write commands to /etc/rc.local
            sudo bash -c "echo '#!/bin/bash' > /etc/rc.local"
            sudo bash -c "echo '$commands' >> /etc/rc.local"
            sudo chmod +x /etc/rc.local
            echo "Commands for 6to4 multi server (1 outside 2 Iran) have been set."
            ;;
        *)
            echo "Invalid option. Please select 1, 2, or 3."
            return
            ;;
    esac
}

# Function to handle removing tunnels
remove_tunnels() {
    echo "Removing tunnels..."
    # Add your commands to remove tunnels here
}

# Function to enable BBR
enable_bbr() {
    echo "Enabling BBR..."
    # Add your commands to enable BBR here
}

# Function to fix WhatsApp time
fix_whatsapp_time() {
    echo "Fixing WhatsApp time..."
    # Add your commands to fix WhatsApp time here
}

# Function to optimize system
optimize_system() {
    echo "Optimizing system..."
    # Add your commands to optimize the system here
}

# Function to install x-ui
install_x_ui() {
    echo "Installing x-ui..."
    # Add your commands to install x-ui here
}

# Function to change nameserver
change_nameserver() {
    echo "Changing nameserver..."
    # Add your commands to change nameserver here
}

# Function to disable IPv6
disable_ipv6() {
    echo "Disabling IPv6..."
    # Add your commands to disable IPv6 here
}

# Main script execution
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
read -p "Select an option (1, 2, 3, 4, 5, 6, 7, 8, 9, or 10): " option

case $option in
    1)
        handle_six_to_four
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
        optimize_system
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
