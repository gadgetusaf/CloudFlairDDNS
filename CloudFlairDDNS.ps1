function Start-CloudFlairDNSUpdate {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory=$true)]
      [string]$AuthEmail,
      [Parameter(Mandatory=$true)]
      [string]$AuthKey,
      [Parameter(Mandatory=$true)]
      [string]$FactsPath
    )
    $IpInfoToken = 
    $CurrentIP = ((Invoke-WebRequest -UseBasicParsing -Uri https://ipinfo.io/what-is-my-ip?token=$IpInfoToken) | ConvertFrom-Json).ip
    $HostList = Import-Csv -Path $FactsPath -Delimiter `t
    foreach ($SingleHost in $HostList) {
        if ((Test-NetConnection $SingleHost.name).RemoteAddress.IPAddressToString -ne $CurrentIP) {
            write-host "$SingleHost Update required"
            Update-CloudflareDns -ZoneId $SingleHost.zone_id -RecordId $SingleHost.id -Name $SingleHost.name -AuthEmail $AuthEmail -AuthKey $AuthKey -RecordType $SingleHost.type -IPAddress $CurrentIP
        } else {
            write-host "$SingleHost good"
        }
    }
  }

  function Get-CloudflareDns {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory=$true)]
      [string]$AuthEmail,
      [Parameter(Mandatory=$true)]
      [string]$AuthKey
    )
  
    # Set up the request header
    $header = @{
      'X-Auth-Email' = "$AuthEmail"
      'X-Auth-Key' = "$AuthKey"
      'Content-Type' = "application/json"
    }
  
    # Make the request to list the DNS zones
  
    $uri = "https://api.cloudflare.com/client/v4/zones?per_page=2"
    $response = Invoke-WebRequest -Method GET -Uri $uri -Headers $header -UseBasicParsing
    $json = $response.Content | ConvertFrom-Json  
    $zones = $json.result
    if ($json.result_info.total_pages -gt 1){
      do {
        $PageToCall = $json.result_info.page + 1
        $uri = "https://api.cloudflare.com/client/v4/zones?per_page=2&page=$($PageToCall)"
        $response = Invoke-WebRequest -Method GET -Uri $uri -Headers $header -UseBasicParsing
        $json = $response.Content | ConvertFrom-Json  
        $zones += $json.result
      } until (
        $json.result_info.total_pages -eq $json.result_info.page
      )
    }
    $records = @()
    foreach ($zone in $zones) {
            [int]$CurrentPage = 1
            $uri = "https://api.cloudflare.com/client/v4/zones/$($zone.id)/dns_records?per_page=100"
            $response = Invoke-WebRequest -Method GET -Uri $uri -Headers $header -UseBasicParsing
            $json = $response.Content | ConvertFrom-Json
            $records += $json.result
            if ($json.result_info.page -ne $json.result_info.total_pages){
              do {
                start-sleep -Milliseconds 250
                $CurrentPage = $json.result_info.page + 1
                $uri = "https://api.cloudflare.com/client/v4/zones/$($zone.id)/dns_records?per_page=100&page=$CurrentPage"
                $response = Invoke-WebRequest -Method GET -Uri $uri -Headers $header -UseBasicParsing
                $json = $response.Content | ConvertFrom-Json
                $records += $json.result
            } until (
                $json.result_info.page -eq $json.result_info.total_pages
            )
            }
        } 
    return $records
  }

  function Update-CloudflareDns {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ZoneId,
        [Parameter(Mandatory=$true)]
        [string]$RecordId,
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [string]$AuthEmail,
        [Parameter(Mandatory=$true)]
        [string]$AuthKey,
        [Parameter(Mandatory=$true)]
        [string]$RecordType,
        [Parameter(Mandatory=$true)]
        [string]$IPAddress        
    )
    $Type = $RecordType
    $Content = $IPAddress 
 
    # Set up the request header
    $header = @{
        'X-Auth-Email' = $AuthEmail
        'X-Auth-Key' = $AuthKey
        'Content-Type' = 'application/json'
    }
 
    # Set up the request body
    $body = @{
        'type' = $Type
        'name' = $Name
        'content' = $Content
    }
 
    # Make the request to update the DNS record
    $uri = "https://api.cloudflare.com/client/v4/zones/$ZoneId/dns_records/$RecordId"
    $response = Invoke-WebRequest -Method PUT -Uri $uri -Headers $header -Body ($body | ConvertTo-Json)
 
    # Check the response status code
    if ($response.StatusCode -eq 200) {
        Write-Output "DNS update successful"
    }
    else {
        Write-Output "DNS update failed: $($response.StatusCode) $($response.StatusDescription)"
    }
 }