RED="\033[0;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
RESET="\033[0m"


print_check() {
    local label="$1"
    local status="$2"
    local message="$3"

    case $status in
        OK)
            echo -e "[${GREEN}OK${RESET}]     $label - $message"
            ;;
        WARN)
            echo -e "[${YELLOW}WARNING${RESET}]     $label - $message"
            ;;
        FAIL)
            echo -e "[${RED}FAILED${RESET}]     $label - $message"
            ;;
    esac
}

check_disk() {
    local threashold=80
    local usage

    usage=$(df -h / | awk 'NR==2 {gsub("%","",$5); print $5 }')

    if (( usage >= threashold )); then
        print_check "Disk Usage" "FAIL" "Root filesystem at ${usage}%"
        return 1
    elif (( usage >= threashold - 10 )); then
        print_check "Disk Usage" "WARN" "Root filesystem at ${usage}%"
        return 0
    else
        print_check "Disk Usage" "OK" "Root filesystem at ${usage}%"
        return 0
    fi
}

check_memory() {
    local threashold=80
    local mem_total mem_available mem_used usage

    if [[ ! -f /proc/meminfo ]]; then
        print_check "Memory Usage" "WARN" "Not supported on non-Linux systems"
        return 0
    fi
    

    mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)

    mem_used=$(($mem_total - $mem_available))
    
    usage=$(( mem_used * 100 / mem_total ))

    if (( usage >= threshold )); then
        print_check "Memory Usage" "FAIL" "${usage}% used"
        return 1
    elif (( usage >= threshold - 10 )); then
        print_check "Memory Usage" "WARN" "${usage}% used"
        return 0
    else
        print_check "Memory Usage" "OK" "${usage}% used"
        return 0
    fi
}


healthcheck_main() {
    echo "Running system health checks..."
    echo

    local failures=0

    check_disk || failures=$((failures+1))
    check_memory || failures=$((failures+1))

    echo
    if (( failures > 0 )); then
        echo -e "${RED}Health check failed with ${failures} issue(s).${RESET}"
        return 1
    else
        echo -e "${GREEN}All checks passed.${RESET}"
        return 0
    fi
}