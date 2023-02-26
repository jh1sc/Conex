Add-Type -AssemblyName  Microsoft.VisualBasic, PresentationCore, PresentationFramework, System.Drawing, System.Windows.Forms, WindowsBase, WindowsFormsIntegration, System; 
iwr -Uri "https://raw.githubusercontent.com/jh1sc/Posh-Header/main/Posh-H.psm1" -OutFile "$env:temp\Posh-H.psm1"; ipmo "$env:temp\Posh-H.psm1"; Header
$F = [Windows.Native.Kernel32]::GetCurrentConsoleFontEx(); $F.FontIndex = 0; $F.FontWidth = 6; $F.FontHeight = 12; $F.FontFamily = 54; $F.FontWeight = 1000; $F.FaceName = "SimSun-ExtB"; [Windows.Native.Kernel32]::SetCurrentConsoleFontEx($F)
write-host "CONEX"
#Get-ArpCache
function GAC {
    $regexIPv4Address = '(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'
    $regexMACAddress = '([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})|([0-9A-Fa-f]{2}){6}'
    arp -a | Foreach-Object { if ($_ -like "*---*") { $interfaceIPv4 = [regex]::Matches($_, $regexIPv4Address).Value } elseif ($_ -match $regexMACAddress) {
            $ipv4Address = $_.Split(" ") | Where-Object { $_ -match $regexIPv4Address }; $macAddress = $_.Split(" ") | Where-Object { $_ -match $regexMACAddress } | ForEach-Object { $_.ToUpper() }
            $type = $_.Split(" ") | Where-Object { ![String]::IsNullOrEmpty($_) -and $_ -notmatch $regexIPv4Address -and $_ -notmatch $regexMACAddress }
            [pscustomobject]@{Interface = $interfaceIPv4; IPv4Address = $ipv4Address; MACAddress = $macAddress; Type = $type }
        }
    }
}
(GAC).IPv4Address
$SendingIP = Read-Host "Client ADDRESS"
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


$BindingIP = ((Get-NetIPAddress | Where-Object { $_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00" }).IPAddress)
$icmp = [Icmp]::new()
$icmp.InitAll(20, $SendingIP, $BindingIP, "InterNetwork", "Raw", "Icmp")

Clear-Host
$icmp.sBytes("H_IP"); $icmp.sBytes($BindingIP)
$icmp.Receive(); $banner = $icmp.Flush(); Write-Host $banner
$icmp.Receive(); Write-Host -NoNewline ($icmp.Flush()); 
$inp = $Host.UI.ReadLine(); $icmp.sBytes($inp)


While (1) {
    $icmp.Receive()
    if (($icmp.Flush()) -eq "File") {
        $icmp.sBytes(" "); $e = $false
        $pos = $host.ui.rawui.cursorposition
        while ($e -eq $false) {
            $icmp.Receive()
            if (($icmp.Flush()) -eq "End") {
                $e = $true
                Start-Process "$env:temp\TMP_1827.txt" 
            }
            elseif ($icmp.Flush() -ne "End") {
                $host.ui.rawui.cursorposition = $pos
                Write-host ($icmp.Flush());$icmp.Receive()
                ($icmp.Flush()) >> "$env:temp\TMP_1827.txt" 
                $icmp.sBytes(" ")
            }
        }
        $icmp.Receive()
    }
    else {
        Write-Host ($icmp.Flush())
    }
    $icmp.Receive()
    Write-Host -NoNewline ($icmp.Flush()); $inp = $Host.UI.ReadLine()
    if ($inp -eq "cls"){
        clear-host 
        Write-Host $banner
    }
    $icmp.sBytes($inp)
}



