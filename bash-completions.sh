#!/bin/bash

# Cloud endpoint URL
CLOUD_ENDPOINT="https://your-cloud-endpoint.com/ai-completion"

# Prompt for token at the time of sourcing this script
echo -n "Enter token for 'f': "
read -s F_TOKEN
echo
echo "Token set for session."

# Function to fetch completions from the cloud using the token
_fetch_completions_from_cloud() {
    local cur=${COMP_WORDS[*]:1}  # Get all words typed so far, excluding the command itself

    # Make a request to the cloud endpoint. Adjust this as needed for your API.
    # Here, we're sending the current command line input as a query parameter.
    curl -s -G --data-urlencode "input=$cur" --header "Authorization: Bearer $F_TOKEN" "$CLOUD_ENDPOINT"
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
            local commands=$(cat augment_history.txt)  # Assuming augment_history.txt contains one command per line
            COMPREPLY=($(compgen -W "${commands}" -- ${current}))
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}

# Register the completion function
complete -F _ai_completion ai


