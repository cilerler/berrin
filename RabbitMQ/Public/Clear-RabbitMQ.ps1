function Clear-RabbitMQ {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$RabbitMQManagementAPI = "http://host.docker.internal:15672/api",
        [Parameter(Mandatory = $false)]
        [string]$UserName = "useradmin",
        [Parameter(Mandatory = $false)]
        [string]$Password = "passwordadmin"
    )
	
    $creds = New-Object System.Management.Automation.PSCredential ($Username, (ConvertTo-SecureString $Password -AsPlainText -Force))

    $exchanges = Invoke-RestMethod -AllowUnencryptedAuthentication -Method Get -Uri "$RabbitMQManagementAPI/exchanges/%2f"  -Credential $creds
    $queues = Invoke-RestMethod -AllowUnencryptedAuthentication -Method Get -Uri "$RabbitMQManagementAPI/queues/%2f" -Credential $creds

    $filteredItems1 = $exchanges | Where-Object { $_.user_who_performed_action -ne 'rmq-internal' } | Select-Object -ExpandProperty name | ForEach-Object { New-Object PSObject -property @{type="exchanges"; name=$_} }
    $filteredItems2 = $queues | Select-Object -ExpandProperty name | ForEach-Object { New-Object PSObject -property @{type="queues"; name=$_} }

    $filteredItems = $filteredItems1 + $filteredItems2
    $filteredItems | ForEach-Object {
        $itemType = $_.type
        $itemName = $_.name

        $deleteUri = "$RabbitMQManagementAPI/$itemType/%2f/$itemName"
        Invoke-RestMethod -AllowUnencryptedAuthentication -Method Delete -Uri $deleteUri -Credential $creds
    }

    Write-Output "Non-default exchanges and queues have been cleaned.";
}
