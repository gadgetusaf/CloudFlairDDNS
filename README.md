# CloudFlairDDNS

CloudFlairDDNS is a collection of PowerShell and Bash scripts designed to dynamically check and update your Cloudflare DNS records. This repository provides tools to manage DNS records efficiently by automating the process of updating DNS records based on your current IP address.

## Features

- **List DNS Records**: Retrieve and list all DNS records for your Cloudflare zones.
- **Automated DNS Updates**: Automatically update DNS records based on the current IP address.

## Prerequisites

- **PowerShell 5.1 or later** (for Windows scripts)
- **Bash** (for Unix-like systems)
- **Cloudflare API key and email**

## Installation

### PowerShell

1. Clone the repository or download the scripts.
2. Save the scripts to a directory on your machine.

### Bash

1. Clone the repository or download the scripts.
2. Ensure you have `curl` and `jq` installed.

## Usage

### PowerShell

#### List DNS Records

The `get-CloudflairDNSList` function retrieves and lists all DNS records for your Cloudflare zones.

```powershell
get-CloudflairDNSList -AuthEmail "your-email@example.com" -AuthKey "your-api-key"
```

#### Automated DNS Update V2

The `Start-CloudFlairDNSUpdateV2` function starts the automated DNS update process, checking your current IP address and updating DNS records if necessary.

```powershell
Start-CloudFlairDNSUpdateV2 -AuthEmail "your-email@example.com" -AuthKey "your-api-key" -FactsPath "C:\powershell\allinfo.csv"
```

### Bash

#### Automated DNS Update V2

The `update.sh` script starts the automated DNS update process, checking your current IP address and updating DNS records if necessary.

```bash
./update.sh -e your-email@example.com -k your-api-key -f /path/to/facts.csv [-v]
```

## CSV File Format

The CSV file used for automated DNS updates should have the following columns:

- `zone_name`
- `zone_id`
- `record_id`
- `record_type`
- `record_name`
- `record_content`

Example:

```csv
"Zone Name","Zone ID","Record ID","Record Type","Record Name","Record Content"
"example.com","zone-id-1","record-id-1","A","www.example.com","1.2.3.4"
```

## Functions

### PowerShell

- **get-CloudflairDNSList**: Retrieves a list of DNS records and formats them.
- **Start-CloudFlairDNSUpdateV2**: Starts the automated DNS update process with additional parameters.

### Bash

- **update_cloudflare_dns_v2**: Updates a DNS record with the given parameters.
- **start_cloudflare_dns_update_v2**: Starts the automated DNS update process.

## Examples

### Example PowerShell Usage

```powershell
# List DNS records
$dnsRecords = get-CloudflairDNSList -AuthEmail "your-email@example.com" -AuthKey "your-api-key"
$dnsRecords | Format-Table

# Automated DNS update V2
Start-CloudFlairDNSUpdateV2 -AuthEmail "your-email@example.com" -AuthKey "your-api-key" -FactsPath "C:\powershell\allinfo.csv"
```

### Example Bash Usage

```bash
# Automated DNS update V2
./update.sh -e your-email@example.com -k your-api-key -f /path/to/facts.csv -v
```

## License

This project is licensed under the MIT License.
