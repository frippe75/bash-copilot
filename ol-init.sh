#!/bin/bash

# Version: 0.05

# Initialize script continuation flag
continue_script=true

# Define color codes
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"

# Firebase project's Web API Key
API_KEY="AIzaSyAfEt2dv_-RFIIf2BiY_n1419lQX5YNti0"

# Firebase Auth endpoint for email & password authentication
FIREBASE_AUTH_ENDPOINT="https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}"

# Check for terminal color support
if tput colors > /dev/null 2>&1; then
    num_colors=$(tput colors)
    if [ "$num_colors" -ge 8 ]; then
        # debug "Terminal supports colors"
        COLOR_SUPPORT=1
    else
        COLOR_SUPPORT=0
        # debug "Terminal does not support colors"
    fi
else
    COLOR_SUPPORT=0
    # debug "Cannot determine color support with tput"
fi

handle_error() {
    echo_color red "Error: $1"
    continue_script=false
}

echo_color() {
    local color_code="$1"
    local message="$2"
    case $color_code in
        red) color_code="\033[31m" ;;
        green) color_code="\033[32m" ;;
        yellow) color_code="\033[33m" ;;
        blue) color_code="\033[34m" ;;
        purple) color_code="\033[35m" ;;
        cyan) color_code="\033[36m" ;;
        *) color_code="\033[0m" ;;  # Default to no color if not specified
    esac
    echo -e "${color_code}${message}\033[0m"
}

_ol_debug() {
    if [ -n "$_OL_DEBUG" ]; then echo_color cyan "DEBUG: $1"; fi
}


# Cloud endpoint URL
if [[ -z "$DEV" ]]; then
    SCRIPT_ENDPOINT="https://bash-ai-backend-service-bzr66ksiqq-ey.a.run.app/script"
    VERSION_ENDPOINT="https://bash-ai-backend-service-bzr66ksiqq-ey.a.run.app/version"
else
    source .env
    _ol_debug "Running in env DEV"
fi

_ol_warm_up_service() {
    #echo_color cyan "Contacting cloud services to wake them up..."

    # Disable job control messages
    set +m

    # Run curl in a subshell in the background
    (curl -s "$VERSION_ENDPOINT" > /dev/null 2>&1 &)

    # Re-enable job control messages if needed elsewhere in the script
    set -m
}


_ol_do_authentication() {
    if [[ -z "$DEV" ]]; then
        # Warm up cloud services before taking user input
    	_ol_warm_up_service

        printf "Please enter your email: "
        read -r email
        printf "Please enter your password: "
        read -sr password
        echo
    else
        source .env
    fi

    # Authenticate with Firebase and get an ID token
    response=$(curl -s -X POST "${FIREBASE_AUTH_ENDPOINT}" \
                    -H "Content-Type: application/json" \
                    --data-binary "{\"email\":\"${email}\",\"password\":\"${password}\",\"returnSecureToken\":true}")

    # Clear email and password from memory
    unset email password

    echo

    # Check if the response contains "idToken"
    if echo "$response" | grep -q "idToken"; then
        # Extract the ID token using awk for platform independence since grep could cause issues on some systems
        #token=$(echo "$response" | awk -F'"idToken":' '{print $2}' | awk -F'"' '{print $2}')
        #token=$(echo "$response" | awk -F'"idToken":' '{print $2}' | awk -F'"' '{print $2}' | tr -d ' ')
        token=$(echo "$response" | awk -F'"idToken":' '{print $2}' | awk -F'"' '{print $2}' | sed 's/^ *//;s/ *$//' | tr -d '\n')

        echo_color green "Authentication successful."
        # Proceed with the rest of the script
    else
        # Handle errors
        # Extract the error message
        error_message=$(echo "$response" | grep -o '"message":"[^"]*' | cut -d'"' -f4)
        handle_error "Authentication failed with error: $error_message"
    fi

    echo
}

_ol_inject_script() {
    # Exit if a previous error occurred
    if [[ "$continue_script" == false ]]; then
        return
    fi

    # Obtain the context, which is the hostname in this case
    context=$(whoami)@$(hostname -f)

    # Fetch the base64 encoded script 
    source <(curl -sL $SCRIPT_ENDPOINT \
                -X POST \
                -H "Authorization: Bearer ${token}" \
                -H "Content-Type: application/json" \
                --data-binary "{\"context\":\"$context\"}" | base64 -d)
}



# Execute the defined functions
_ol_do_authentication
_ol_inject_script

