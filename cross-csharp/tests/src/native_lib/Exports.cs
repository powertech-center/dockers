using System.Runtime.InteropServices;

public static class Exports
{
    [UnmanagedCallersOnly(EntryPoint = "answer")]
    public static int Answer() => 42;
}
