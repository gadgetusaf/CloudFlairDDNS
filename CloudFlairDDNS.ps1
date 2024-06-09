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
  
  
  
  function Update-CloudflareDnsContent {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory=$true)]
      [string]$ZoneId,
      [Parameter(Mandatory=$true)]
      [string]$RecordId,
      [Parameter(Mandatory=$true)]
      [string]$Content,
      [Parameter(Mandatory=$true)]
      [string]$AuthEmail,
      [Parameter(Mandatory=$true)]
      [string]$AuthKey
    )
  
    # Set up the request header and body
    $header = @{
      'X-Auth-Email' = "$AuthEmail"
      'X-Auth-Key' = "$AuthKey"
      'Content-Type' = "application/json"
    } | ConvertTo-Json
    $body = @{
      content = $Content
    } | ConvertTo-Json
  
    # Make the request to update the DNS record
    $uri = "https://api.cloudflare.com/client/v4/zones/{$ZoneId}/dns_records/{$RecordId}"
    $response = Invoke-WebRequest -Method PUT -Uri $uri -Headers $header -Body $body
  
    # Check the response status code
    if ($response.StatusCode -eq 200) {
      Write-Output "DNS update successful"
    }
    else {
      Write-Output "DNS update failed: $($response.StatusCode) $($response.StatusDescription)"
    }
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
      [string]$Content
    )
    $type = 'A'
    # Set up the request header and body
    $header = @{
      'X-Auth-Email' = "$AuthEmail"
      'X-Auth-Key' = "$AuthKey"
      'Content-Type' = 'applicationjson'
    } | ConvertTo-Json
    $body = @{
      'type' = "$Type"
      'name' = "$Name"
      'content' = "$Content"
    } | ConvertTo-Json
  
    # Make the request to update the DNS record
    $uri = "https://api.cloudflare.com/client/v4/zones/{$ZoneId}/dns_records/{$RecordId}"
    $response = Invoke-WebRequest -Method PUT -Uri $uri -Headers $header -Body $body
  
    # Check the response status code
    if ($response.StatusCode -eq 200) {
      Write-Output "DNS update successful"
    }
    else {
      Write-Output "DNS update failed: $($response.StatusCode) $($response.StatusDescription)"
    }
  }
  
  
  function Start-CloudFlairDNSUpdate {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory=$true)]
      [string]$AuthEmail,
      [Parameter(Mandatory=$true)]
      [string]$AuthKey
    )
    $HostList = Import-Csv -Path C:\powershell\allinfo.csv -Delimiter `t
    foreach ($SingleHost in $HostList) {
        if ((Test-NetConnection $SingleHost.name).RemoteAddress.IPAddressToString -ne (Resolve-DnsName  o-o.myaddr.l.ipv4.google.com -Type TXT -Server (Resolve-DnsName ns1.google.com -Type a).IPAddress).Strings) {
            write-host "$SingleHost Updating"
            Update-CloudflareDns -ZoneId $SingleHost.ZoneId -RecordId $SingleHost.RecordId -Name $SingleHost.name -AuthEmail $AuthEmail -AuthKey $AuthKey
        } else {
            write-host "$SingleHost good"
        }
    }
  }
  
  function Create-CloudflareDnsRecord {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory=$true)]
      [string]$ZoneId,
      [Parameter(Mandatory=$true)]
      [string]$Name,
      [Parameter(Mandatory=$true)]
      [string]$Type,
      [Parameter(Mandatory=$true)]
      [string]$Content,
      [Parameter(Mandatory=$true)]
      [string]$AuthEmail,
      [Parameter(Mandatory=$true)]
      [string]$AuthKey
    )
  
    # Set up the request header and body
    $header = @{
      'X-Auth-Email' = "$AuthEmail"
      'X-Auth-Key' = "$AuthKey"
      'Content-Type' = "application/json"
    }
    $body = @{
      name = $Name
      type = $Type
      content = $Content
    } | ConvertTo-Json
  
    # Make the request to create the DNS record
    $uri = "https://api.cloudflare.com/client/v4/zones/$ZoneId/dns_records"
    $response = Invoke-WebRequest -Method POST -Uri $uri -Headers $header -Body $body
  
    # Check the response status code
    if ($response.StatusCode -eq 200) {
      Write-Output "DNS record created successfully"
    }
    else {
      Write-Output "Failed to create DNS record: $($response.StatusCode) $($response.StatusDescription)"
    }
  }
  
  function Update-CloudflareDnsV2 {
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
        [string]$Content
    )
    $Type = $RecordType
 
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
  
  function Start-CloudFlairDNSUpdateV2 {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory=$true)]
      [string]$AuthEmail,
      [Parameter(Mandatory=$true)]
      [string]$AuthKey,
      [Parameter(Mandatory=$true)]
      [string]$FactsPath
    )
    $CurrentIP = (Resolve-DnsName  o-o.myaddr.l.ipv4.google.com -Type TXT -Server (Resolve-DnsName ns1.google.com -Type a).IPAddress).Strings
    $HostList = Import-Csv -Path $FactsPath -Delimiter `t
    foreach ($SingleHost in $HostList) {
        if ((Test-NetConnection $SingleHost.name).RemoteAddress.IPAddressToString -ne $CurrentIP) {
            write-host "$SingleHost Update required"
            Update-CloudflareDnsV2 -ZoneId $SingleHost.zone_id -RecordId $SingleHost.id -Name $SingleHost.name -AuthEmail $AuthEmail -AuthKey $AuthKey -RecordType $SingleHost.type -Content $CurrentIP
        } else {
            write-host "$SingleHost good"
        }
    }
  }
  
  Function get-CloudflairDNSList {
    [CmdletBinding()]
    param(
      [Parameter(Mandatory=$true)]
      [string]$AuthEmail,
      [Parameter(Mandatory=$true)]
      [string]$AuthKey
    )
    $DNSList = Get-CloudflareDns -AuthEmail $AuthEmail -AuthKey $AuthKey
    $Report  = @()
    foreach ($DNSHost in $DNSList) {
      $obj = new-object psobject
      $obj | Add-Member -MemberType NoteProperty -Name id -Value $DNSHost.id
      $obj | Add-Member -MemberType NoteProperty -Name zone_id -Value $DNSHost.zone_id
      $obj | Add-Member -MemberType NoteProperty -Name zone_name -Value $DNSHost.userEmail
      $obj | Add-Member -MemberType NoteProperty -Name name -Value $DNSHost.name
      $obj | Add-Member -MemberType NoteProperty -Name type -Value $DNSHost.type
      $obj | Add-Member -MemberType NoteProperty -Name content -Value $DNSHost.content
      $Report += $obj
    }
    return $Report
  } 
 

  Start-CloudFlairDNSUpdateV2  -AuthEmail [email] -AuthKey [apikey] -FactsPath "C:\powershell\allinfo.csv"  
