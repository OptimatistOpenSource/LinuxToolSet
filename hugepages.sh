#!/bin/bash

function enable_hugepages() {
    if [ -z "$1" ]; then
        echo "Usage: enable_hugepages <number_of_pages>"
        return 1
    fi

    local num_pages=$1

#    echo "Enabling HugePages with $num_pages pages..."
#    sysctl -w "vm.nr_hugepages=$num_pages"
#    echo "HugePages enabled successfully with $num_pages pages."
    if ! [[ "$num_pages" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a positive integer for the number of normal HugePages."
        return 1
    fi

    echo "Enabling HugePages with $num_pages pages..."
    if sysctl -w "vm.nr_hugepages=$num_pages" && sysctl -p; then
        echo "HugePages enabled successfully with $num_pages pages."
    else
        echo "Error enabling HugePages."
        return 1
    fi
}

function disable_hugepages() {
    echo "Disabling HugePages..."
    sysctl -w "vm.nr_hugepages=0"
    echo "HugePages disabled successfully."
}

function check_thp_status() {
    thp_status=$(cat /sys/kernel/mm/transparent_hugepage/enabled)
    if [ "$thp_status" == "always madvise [never]" ]; then
        echo "Transparent Huge Pages (THP) are currently disabled."
        return 0
    else
        echo "Transparent Huge Pages (THP) are currently enabled."
        return 1
    fi
}

function enable_thp() {
    echo "Enabling Transparent Huge Pages (THP)..."
    echo -n "/sys/kernel/mm/transparent_hugepage/enabled "
    echo "always" | tee /sys/kernel/mm/transparent_hugepage/enabled
    echo -n "/sys/kernel/mm/transparent_hugepage/defrag "
    echo "madvise" | tee /sys/kernel/mm/transparent_hugepage/defrag
    echo "THP enabled successfully."
}

function disable_thp() {
    echo "Disabling Transparent Huge Pages (THP)..."
    echo "never" | tee /sys/kernel/mm/transparent_hugepage/enabled
    echo "THP disabled successfully."
}

function display_status() {
    echo "Normal HugePages status:"
    grep "HugePages" /proc/meminfo

    echo -e "\nTransparent Huge Pages (THP) status:"
    echo -n "/sys/kernel/mm/transparent_hugepage/enabled "
    cat /sys/kernel/mm/transparent_hugepage/enabled
    echo -n "/sys/kernel/mm/transparent_hugepage/defrag "
    cat /sys/kernel/mm/transparent_hugepage/defrag
}

echo "Choose an option:"
echo "1. Enable and set the number of normal HugePages"
echo "2. Disable of normal HugePages"
echo "3. Enable Transparent Huge Pages (THP)"
echo "4. Disable Transparent Huge Pages (THP)"
echo "5. Display HugePages and THP status"
echo -n "Enter your choice (1, 2, 3, 4, or 5): " 
read choice

case $choice in
    1)
        echo -n "Enter the number of normal HugePages: "
        read num_pages
        enable_hugepages "$num_pages"
        ;;
    2)
        disable_hugepages
        ;;
    3)
        if check_thp_status; then
            enable_thp
        fi
        ;;
    4)
        if ! check_thp_status; then
            disable_thp
        fi
        ;;
    5)
	display_status
	;;
    *)
        echo "Invalid choice. Please enter 1, 2, 3, 4, or 5"
        ;;
esac
