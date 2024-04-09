#!/bin/bash

# Version: 0.04

# Firebase project's Web API Key
API_KEY="your_firebase_api_key"

# Firebase Auth endpoint for email & password authentication
FIREBASE_AUTH_ENDPOINT="https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"

# Your FastAPI endpoint
ENDPOINT="https://api.frippe.com/v1/script"

printf "Please enter your email: "
read -r email
printf "Please enter your password: "
read -sr password
echo

# Authenticate with Firebase and get an ID token
response=$(curl -s -X POST "${FIREBASE_AUTH_ENDPOINT}?key=${API_KEY}" \
                -H "Content-Type: application/json" \
                --data-binary "{\"email\":\"${email}\",\"password\":\"${password}\",\"returnSecureToken\":true}")

# Extract the ID token using grep and cut
token=$(echo "$response" | grep -o '"idToken":"[^"]*' | cut -d'"' -f4)

# Clear email and password from memory
unset email password

if [ -z "$token" ]; then
  echo "Error: Authentication failed."
  #exit 1
fi

echo "Authentication successful."

# Obtain the context, which is the hostname in this case
context=$(hostname)

# Fetch the script from your FastAPI application
HTTP_STATUS=$(curl -s -o script.sh -w "%{http_code}" "$ENDPOINT" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            --data-binary "{\"context\":\"$context\"}")

# Check the HTTP status code
if [ "$HTTP_STATUS" -ne 200 ]; then
  echo "Failed to fetch the script. HTTP Status: $HTTP_STATUS"
  exit 1
fi

# Execute the fetched script if it was successfully downloaded
if [ -s script.sh ]; then
    source script.sh
    rm script.sh  # Clean up the script file after execution
else
    echo "Error: The script file is empty or not found."
    # Exit will exit the shell if sourced
    #exit 1
fi

