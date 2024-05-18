#!/bin/bash

# Check if the email address and API token are provided as command-line arguments
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Please provide your Cloudflare email address and API token as command-line arguments."
  echo "Usage: ./export_dns_records.sh email_address api_token"
  exit 1
fi

# Set your Cloudflare email address and API token from the command-line arguments
EMAIL_ADDRESS="$1"
API_TOKEN="$2"

# Set the output CSV file path
OUTPUT_FILE="dns_records.csv"

# Function to retrieve DNS records for a given zone
get_dns_records() {
  local zone_id=$1
  local page=1
  local per_page=100
  local records=""

  while true; do
    response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?page=$page&per_page=$per_page" \
      -H "X-Auth-Email: $EMAIL_ADDRESS" \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json")

    if echo "$response" | jq -e '.result' >/dev/null 2>&1; then
      records+=$(echo "$response" | jq -r '.result[] | [.id, .type, .name, .content] | @csv')
    else
      echo "Error retrieving DNS records for zone $zone_id. Skipping..."
      break
    fi

    if echo "$response" | jq -e '.result_info.total_pages' >/dev/null 2>&1; then
      total_pages=$(echo "$response" | jq -r '.result_info.total_pages')
      if [ $page -ge $total_pages ]; then
        break
      fi
    else
      break
    fi

    ((page++))
    sleep 1  # Simple rate limiting
  done

  echo "$records"
}

# Retrieve the list of zones
zones_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?status=active" \
  -H "X-Auth-Email: $EMAIL_ADDRESS" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json")

if echo "$zones_response" | jq -e '.result' >/dev/null 2>&1; then
  # Extract the zone IDs and names from the response
  zone_data=$(echo "$zones_response" | jq -r '.result[] | [.id, .name] | @tsv')

  # Create the CSV file with headers
  echo "Zone Name,Zone ID,Record ID,Record Type,Record Name,Record Content" > "$OUTPUT_FILE"

  # Iterate over each zone and retrieve DNS records
  while IFS=$'\t' read -r zone_id zone_name; do
    dns_records=$(get_dns_records "$zone_id")
    
    # Append the zone name and ID to each DNS record and write to the CSV file
    while IFS= read -r record; do
      if [ -n "$record" ]; then
        echo "\"$zone_name\",\"$zone_id\",$record" >> "$OUTPUT_FILE"
      fi
    done <<< "$dns_records"
  done <<< "$zone_data"

  echo "DNS records exported to $OUTPUT_FILE"
else
  echo "Error retrieving zones. Please check your email address and API token."
fi
root@localhost:~# ^C
root@localhost:~# ./get-dns.sh Chris.Burton@gadgetusaf.com gN9c217Jwwh4Ej30QMh3nN7NJLAhZ1VA8GZTs2oI
DNS records exported to dns_records.csv
root@localhost:~# cat get-dns.sh
#!/bin/bash

# Check if the email address and API token are provided as command-line arguments
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Please provide your Cloudflare email address and API token as command-line arguments."
  echo "Usage: ./export_dns_records.sh email_address api_token"
  exit 1
fi

# Set your Cloudflare email address and API token from the command-line arguments
EMAIL_ADDRESS="$1"
API_TOKEN="$2"

# Set the output CSV file path
OUTPUT_FILE="dns_records.csv"

# Function to retrieve DNS records for a given zone
get_dns_records() {
  local zone_id=$1
  local page=1
  local per_page=100
  local records=""

  while true; do
    response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?page=$page&per_page=$per_page" \
      -H "X-Auth-Email: $EMAIL_ADDRESS" \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json")

    if echo "$response" | jq -e '.result' >/dev/null 2>&1; then
      records+=$(echo "$response" | jq -r '.result[] | [.id, .type, .name, .content] | @csv')
    else
      echo "Error retrieving DNS records for zone $zone_id. Skipping..."
      break
    fi

    if echo "$response" | jq -e '.result_info.total_pages' >/dev/null 2>&1; then
      total_pages=$(echo "$response" | jq -r '.result_info.total_pages')
      if [ $page -ge $total_pages ]; then
        break
      fi
    else
      break
    fi

    ((page++))
    sleep 1  # Simple rate limiting
  done

  echo "$records"
}

# Retrieve the list of zones
zones_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?status=active" \
  -H "X-Auth-Email: $EMAIL_ADDRESS" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json")

if echo "$zones_response" | jq -e '.result' >/dev/null 2>&1; then
  # Extract the zone IDs and names from the response
  zone_data=$(echo "$zones_response" | jq -r '.result[] | [.id, .name] | @tsv')

  # Create the CSV file with headers
  echo "Zone Name,Zone ID,Record ID,Record Type,Record Name,Record Content" > "$OUTPUT_FILE"

  # Iterate over each zone and retrieve DNS records
  while IFS=$'\t' read -r zone_id zone_name; do
    dns_records=$(get_dns_records "$zone_id")
    
    # Append the zone name and ID to each DNS record and write to the CSV file
    while IFS= read -r record; do
      if [ -n "$record" ]; then
        echo "\"$zone_name\",\"$zone_id\",$record" >> "$OUTPUT_FILE"
      fi
    done <<< "$dns_records"
  done <<< "$zone_data"

  echo "DNS records exported to $OUTPUT_FILE"
else
  echo "Error retrieving zones. Please check your email address and API token."
fi