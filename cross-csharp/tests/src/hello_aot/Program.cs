using System;
using System.Runtime.InteropServices;

Console.WriteLine("Hello from NativeAOT!");
Console.WriteLine($"OS: {RuntimeInformation.OSDescription}");
Console.WriteLine($"Arch: {RuntimeInformation.ProcessArchitecture}");
