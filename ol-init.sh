#!/bin/bash

# Version: 0.05

# Initialize script continuation flag
continue_script=true

# Firebase project's Web API Key
API_KEY="AIzaSyAfEt2dv_-RFIIf2BiY_n1419lQX5YNti0"

# Firebase Auth endpoint for email & password authentication
FIREBASE_AUTH_ENDPOINT="https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}"

# Cloud endpoint URL
if [[ -z "$DEV" ]]; then
    SCRIPT_ENDPOINT="https://bash-ai-backend-service-bzr66ksiqq-ey.a.run.app"
else
    source .env
fi


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
    if [[ "$COLOR_SUPPORT" -eq 1 ]]; then
        case "$1" in
            red)
                echo -e "\033[0;31m$2\033[0m"
                ;;
            green)
                echo -e "\033[0;32m$2\033[0m"
                ;;
            yellow)
                echo -e "\033[0;33m$2\033[0m"
                ;;
            *)
                echo "$2"
                ;;
        esac
    else
        echo "$2"
    fi      
}

do_authentication() {
    if [[ -z "$DEV" ]]; then
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

inject_script() {
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

    printf "Oneliners.io loaded for context "
    echo_color yellow $context
    echo 
    echo Tip: To get started type ol \<tab\> for completion
}

final_steps() {
    :
    #echo "Final steps or cleanup..."
}

# Execute the defined functions
do_authentication
inject_script
# Final steps are called regardless of script continuation status to ensure cleanup
final_steps
