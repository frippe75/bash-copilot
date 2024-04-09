#!/bin/bash

# Version: 0.03

# Firebase project's Web API Key
API_KEY="your_firebase_api_key"

# Firebase Auth endpoint for email & password authentication
FIREBASE_AUTH_ENDPOINT="https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"

# FastAPI endpoint
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

# Check if we successfully obtained a token
if [ -z "$token" ]; then
  echo "Authentication failed."
  exit 1
fi

echo "Authentication successful."

# Obtain the context, which is the hostname in this case
context=$(hostname)

# Fetch and execute the script from your FastAPI application
# Pass the context in the request's body
SCRIPT=$(curl -s "$ENDPOINT" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            --data-binary "{\"context\":\"$context\"}")

# Execute the fetched script
eval "$SCRIPT"

