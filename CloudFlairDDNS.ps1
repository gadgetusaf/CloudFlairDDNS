# Define the function to start the Cloudflare DNS update process
function Start-CloudFlairDNSUpdate {
    [CmdletBinding()]
    param(
        # Specify the Cloudflare account email address
        [Parameter(Mandatory=$true)]
        [string]$AuthEmail,

        # Specify the Cloudflare account API key
        [Parameter(Mandatory=$true)]
        [string]$AuthKey,

        # Specify the path to the CSV file containing the DNS records to update
        [Parameter(Mandatory=$true)]
        [string]$FactsPath
    )

    # Get the current public IP address
    $CurrentIP = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json").ip

    # Load the DNS records from the CSV file
    $HostList = Import-Csv -Path $FactsPath -Delimiter `t

    # Iterate through the DNS records
    foreach ($SingleHost in $HostList) {
        # Check if the IP address of the DNS record needs to be updated
        if ($SingleHost.IPAddress -ne $CurrentIP) {
            # Update the DNS record
            Update-CloudflareDns -ZoneId $SingleHost.ZoneId -RecordId $SingleHost.RecordId -Name $SingleHost.Name -AuthEmail $AuthEmail -AuthKey $AuthKey -RecordType $SingleHost.Type -IPAddress $CurrentIP

            # Write a message to indicate that the DNS record was updated
            Write-Host "$($SingleHost.Name) DNS record updated"
        }
        else {
            # Write a message to indicate that the DNS record is up to date
            Write-Host "$($SingleHost.Name) DNS record is up to date"
        }
    }
}

# Define the function to get all DNS records from Cloudflare
function Get-CloudflareDns {
    [CmdletBinding()]
    param(
        # Specify the Cloudflare account email address
        [Parameter(Mandatory=$true)]
        [string]$AuthEmail,

        # Specify the Cloudflare account API key
        [Parameter(Mandatory=$true)]
        [string]$AuthKey
    )

    # Set up the Cloudflare API request headers
    $Headers = @{
        'X-Auth-Email' = $AuthEmail
        'X-Auth-Key' = $AuthKey
        'Content-Type' = 'application/json'
    }

    # Initialize an empty list to store the DNS records
    $Records = @()

    # Get the list of DNS zones
    $Zones = Get-CloudflareZone -Headers $Headers

    # Iterate through the DNS zones
    foreach ($Zone in $Zones) {
        # Get the DNS records for the current zone
        $ZoneRecords = Get-CloudflareDnsRecord -ZoneId $Zone.Id -Headers $Headers

        # Add the DNS records to the list
        $Records += $ZoneRecords
    }

    # Return the list of DNS records
    return $Records
}

# Define the function to update a DNS record in Cloudflare
function Update-CloudflareDns {
    [CmdletBinding()]
    param(
        # Specify the Cloudflare zone ID
        [Parameter(Mandatory=$true)]
        [string]$ZoneId,

        # Specify the Cloudflare DNS record ID
        [Parameter(Mandatory=$true)]
        [string]$RecordId,

        # Specify the DNS record name
        [Parameter(Mandatory=$true)]
        [string]$Name,

        # Specify the Cloudflare account email address
        [Parameter(Mandatory=$true)]
        [string]$AuthEmail,

        # Specify the Cloudflare account API key
        [Parameter(Mandatory=$true)]
        [string]$AuthKey,

        # Specify the DNS record type (e.g., A, CNAME, TXT)
        [Parameter(Mandatory=$true)]
        [string]$RecordType,

        # Specify the IP address or value to update the DNS record with
        [Parameter(Mandatory=$true)]
        [string]$IPAddress
    )

    # Set up the Cloudflare API request headers
    $Headers = @{
        'X-Auth-Email' = $AuthEmail
        'X-Auth-Key' = $AuthKey
        'Content-Type' = 'application/json'
    }

    # Set up the DNS record update data
    $RecordData = @{
        'type' = $RecordType
        'name' = $Name
        'content' = $IPAddress
    }

    # Update the DNS record
    $Response = Update-CloudflareDnsRecord -ZoneId $ZoneId -RecordId $RecordId -Headers $Headers -Body $RecordData

    # Check the response status code
    if ($Response.success -eq $true) {
        Write-Output "DNS update successful"
    }
    else {
        Write-Output "DNS update failed: $($Response.errors[0].code) $($Response.errors[0].message)"
    }
}