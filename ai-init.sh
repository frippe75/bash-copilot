#!/bin/bash

# Version: 0.01

ENDPOINT="https://api.frippe.com/v1"

printf "Please enter your username: "
read -r username
printf "Please enter your password: "
read -sr password
echo

response=$(curl -s -X POST "$ENDPOINT/authenticate" \
                -H "Content-Type: application/json" \
                -d "{\"username\":\"$username\", \"password\":\"$password\"}")
token=$(echo "$response" | grep -oP 'token":"\K[^"]*')

# Clear username and password from memory
unset username password

if [ -z "$token" ]; then
  echo "Authentication failed."
  exit 1
fi

echo "Authentication successful."

context=$(hostname)

# Fetch the script and execute it
SCRIPT=$(curl -s "$ENDPOINT/script" \
            -H "X-API-Key: $token" \
            -d "{\"context\":\"$context\"}")

eval "$SCRIPT"

