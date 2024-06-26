#!/bin/bash

# Cloud endpoint URL
CLOUD_ENDPOINT="http://localhost:8000/chat"
API_KEY="****"


# Prompt for token at the time of sourcing this script
echo -n "Enter API key: "
read -s API_KEY
echo
echo "Token set for session."

# Base function to get completion using curl
# TODO: Look at replacing the uggly HEREDOC EOF 
_fetch_completions() {

    # Prepare the JSON payload
    read -r -d '' PAYLOAD <<EOF
    {
    "user_message": "$1"    
    }
EOF

    # Make the POST request
    curl -s -X POST "$CLOUD_ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "x-api-key: $API_KEY" \
        -d "$PAYLOAD"
}
# Function to fetch completions from the cloud using the token
_fetch_completions_from_cloud() {
    local cur=${COMP_WORDS[*]:1}  # Get all words typed so far, excluding the command itself

    # Make a request to the cloud endpoint. Adjust this as needed for your API.
    # Here, we're sending the current command line input as a query parameter.
    _f_completion "$cur"
}

# The actual completion function
_f_completion() {
    # Fetch completion suggestions from the cloud using the pre-entered token
    local completions=$(_fetch_completions_from_cloud)

    # Use the response to generate completion options
    # This assumes the cloud endpoint returns a space-separated list of suggestions
    COMPREPLY=( $(compgen -W "$completions" -- "${COMP_WORDS[COMP_CWORD]}") )
}

# Register the completion function for the command `f`
complete -F _f_completion f

ai() {
    case "$1" in
        login)
            echo "Authenticating against the AI endpoint..."
            # Authentication logic goes here
            ;;
        aug|augment)
            echo "Enter command to augment: "
            read cmd_to_augment
            echo "Augmenting command: $cmd_to_augment"
            # Send $cmd_to_augment to backend for augmentation
            _fetch_completions "$cmd_to_augment" >> augment_history.txt 
            ;;
        ask)
            echo "Enter your question: "
            read question
            echo "Asking: $question"
            # Send $question to backend and display the answer
            ;;
        run)
            if [[ -n "$2" ]]; then
                echo "Running command from augment history: $2"
                # Logic to execute the command from augment history
            else
                echo "No command specified."
            fi
            ;;
        *)
            echo "Usage: ai [login|augment|ask|run]"
            ;;
    esac
}

_ai_completion() {
    local current=${COMP_WORDS[COMP_CWORD]}
    local prev=${COMP_WORDS[COMP_CWORD-1]}

    case "$prev" in
        ai)
            local opts="login aug augment ask run"
            COMPREPLY=($(compgen -W "${opts}" -- ${current}))
            ;;
        run)
            # Dynamically generate completion options based on the augment history file
            local IFS=$'\n'  # Change IFS to newline for accurate word splitting
            local commands=()
            while IFS= read -r line; do
                commands+=("$line")
            done < "augment_history.txt"
            
            # Use compgen to match against the array of commands
            COMPREPLY=($(compgen -W "${commands[*]}" -- "$current"))
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}

# Register the completion function
complete -F _ai_completion ai



