using System;
using System.Runtime.InteropServices;

// P/Invoke into libc — demonstrates C interop with our cross-compilation sysroots
partial class Program
{
    [LibraryImport("libc", EntryPoint = "getpid")]
    private static partial int NativeGetPid();

    static void Main()
    {
        int pid = NativeGetPid();
        Console.WriteLine($"Hello from NativeAOT with P/Invoke!");
        Console.WriteLine($"getpid() = {pid}");
        Console.WriteLine($"OS: {RuntimeInformation.OSDescription}");
    }
}
