using System;
using System.IO;
using System.Reflection;
public static class InstallerTests
{
    public static int Main(string[] args)
    {
        string root = Path.Combine(Path.GetTempPath(), "cued-installer-tests-" + Guid.NewGuid().ToString("N"));
        string source = Path.Combine(root, "source é space");
        Directory.CreateDirectory(source);
        File.WriteAllText(Path.Combine(source, "original.txt"), "preserve");
        var type = Assembly.LoadFrom(Path.GetFullPath(args[0])).GetType("CuedSetup.SetupForm");
        var copy = type.GetMethod("CopyDirectory", BindingFlags.Static | BindingFlags.NonPublic);
        foreach (var target in new[] { source, Path.Combine(source, "nested", "copy") })
        {
            try { copy.Invoke(null, new object[] { source, target }); throw new Exception("Unsafe copy was accepted"); }
            catch (TargetInvocationException ex) { if (!(ex.InnerException is InvalidOperationException)) throw; }
        }
        if (Directory.Exists(Path.Combine(source, "nested"))) throw new Exception("Unsafe destination was created");
        string destination = Path.Combine(root, "installed é space");
        copy.Invoke(null, new object[] { source, destination });
        if (File.ReadAllText(Path.Combine(destination, "original.txt")) != "preserve") throw new Exception("Normal copy failed");
        Console.WriteLine("{\"passed\":true,\"checks\":[\"reject source itself\",\"reject source descendant before writes\",\"copy separate Unicode destination\"]}");
        return 0;
    }
}
