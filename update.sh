#!/bin/bash

# Function to update Cloudflare DNS V2
update_cloudflare_dns_v2() {
    local zone_id="$1"
    local record_id="$2"
    local name="$3"
    local auth_email="$4"
    local auth_key="$5"
    local record_type="$6"
    local content="$7"
    local verbose="$8"

    # Set up the request header and body
    local header=(
        -H "X-Auth-Email: $auth_email"
        -H "Authorization: Bearer $auth_key"
        -H "Content-Type: application/json"
    )
    local body=$(jq -n --arg type "$record_type" --arg name "$name" --arg content "$content" --argjson ttl 1 '{type: $type, name: $name, content: $content, ttl: $ttl}')

    # Make the request to update the DNS record
    local uri="https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id"
    local response=$(curl -s -w "%{http_code}" -o /dev/null -X PATCH "${header[@]}" -d "$body" "$uri")

    # Check the response status code
    if [ "$response" -eq 200 ]; then
        echo "DNS update successful for $name"
    else
        echo "DNS update failed for $name: $response"
    fi
}

# Function to start Cloudflare DNS update V2
start_cloudflare_dns_update_v2() {
    local auth_email="$1"
    local auth_key="$2"
    local facts_path="$3"
    local verbose="$4"

    local current_ip=$(curl -s https://ipinfo.io/ip)
    if [ -z "$current_ip" ]; then
        echo "Failed to retrieve current IP address"
        exit 1
    fi

    if [ ! -f "$facts_path" ]; then
        echo "CSV file not found: $facts_path"
        exit 1
    fi

    while IFS=',' read -r zone_name zone_id record_id record_type record_name record_content; do
        # Skip the header line
        if [ "$zone_name" == "Zone Name" ]; then
            continue
        fi

        # Remove quotes from fields
        zone_name=$(echo "$zone_name" | tr -d '"')
        zone_id=$(echo "$zone_id" | tr -d '"')
        record_id=$(echo "$record_id" | tr -d '"')
        record_type=$(echo "$record_type" | tr -d '"')
        record_name=$(echo "$record_name" | tr -d '"')
        record_content=$(echo "$record_content" | tr -d '"')

        if [ -z "$zone_id" ] || [ -z "$record_id" ] || [ -z "$record_name" ] || [ -z "$record_type" ]; then
            echo "Skipping invalid line in CSV: $zone_name, $zone_id, $record_id, $record_type, $record_name, $record_content"
            continue
        fi

        # Only process A records (IPv4)
        if [ "$record_type" != "A" ]; then
            if [ "$verbose" == "true" ]; then
                echo "Skipping non-A record: $record_name ($record_type)"
            fi
            continue
        fi

        # Get IPv4 addresses from dig
        remote_ips=$(dig +short "$record_name" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
        match_found=false
        for remote_ip in $remote_ips; do
            if [ "$remote_ip" == "$current_ip" ]; then
                match_found=true
                break
            fi
        done

        if ! $match_found; then
            echo "$record_name Update required"
            if [ "$verbose" == "true" ]; then
                echo "Current IP: $current_ip"
                echo "Remote IPs: $remote_ips"
            fi

            # Update the DNS record
            update_cloudflare_dns_v2 "$zone_id" "$record_id" "$record_name" "$auth_email" "$auth_key" "$record_type" "$current_ip" "$verbose"
        else
            echo "$record_name good"
        fi
    done < "$facts_path"
}

# Parse command-line arguments
while getopts "e:k:f:v" opt; do
    case "${opt}" in
        e)
            auth_email="${OPTARG}"
            ;;
        k)
            auth_key="${OPTARG}"
            ;;
        f)
            facts_path="${OPTARG}"
            ;;
        v)
            verbose="true"
            ;;
        *)
            echo "Usage: $0 -e <auth_email> -k <auth_key> -f <facts_path> [-v]"
            exit 1
            ;;
    esac
done

# Check if all required arguments are provided
if [ -z "${auth_email}" ] || [ -z "${auth_key}" ] || [ -z "${facts_path}" ]; then
    echo "Usage: $0 -e <auth_email> -k <auth_key> -f <facts_path> [-v]"
    exit 1
fi

# Start the Cloudflare DNS update process
start_cloudflare_dns_update_v2 "$auth_email" "$auth_key" "$facts_path" "$verbose"