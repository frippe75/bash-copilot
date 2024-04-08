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

