using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Web.Script.Serialization;

internal static class FixtureParity
{
    private static int Main(string[] args)
    {
        if (args.Length != 3) { Console.Error.WriteLine("Usage: FixtureParity app.exe fixture-directory report.json"); return 2; }
        var serializer = new JavaScriptSerializer();
        Assembly app = Assembly.LoadFrom(Path.GetFullPath(args[0]));
        Type loader = app.GetType("Cued.DeckLoader", true);
        MethodInfo validate = loader.GetMethod("ValidateFile", BindingFlags.Static | BindingFlags.Public);
        MethodInfo load = loader.GetMethod("Load", BindingFlags.Static | BindingFlags.Public);
        var manifest = serializer.Deserialize<Dictionary<string, object>>(File.ReadAllText(Path.Combine(args[1], "manifest.json")));
        var results = new List<object>();
        bool passed = true;
        foreach (Dictionary<string, object> item in (ArrayList)manifest["cases"])
        {
            string file = (string)item["file"];
            string path = Path.Combine(args[1], file);
            object report = validate.Invoke(null, new object[] { path });
            Type reportType = report.GetType();
            var errors = (List<string>)reportType.GetProperty("Errors").GetValue(report, null);
            var warnings = (List<string>)reportType.GetProperty("Warnings").GetValue(report, null);
            object deck = reportType.GetProperty("Deck").GetValue(report, null);
            bool valid = errors.Count == 0;
            bool agrees = valid == (bool)item["valid"] && (!valid || warnings.Count == Convert.ToInt32(item["warnings"]));
            // Exercise the exact Load entry point used by the window as well.
            try
            {
                object loaded = load.Invoke(null, new object[] { path });
                agrees &= valid && loaded != null;
            }
            catch (TargetInvocationException) { agrees &= !valid && deck == null; }
            passed &= agrees;
            results.Add(new { file = file, valid = valid, warnings = warnings.Count, passed = agrees, errors = errors });
            if (!agrees) Console.WriteLine("MISMATCH: " + file);
        }
        File.WriteAllText(args[2], serializer.Serialize(new { platform = "windows", cases = results.Count, passed = passed, results = results }));
        Console.WriteLine((passed ? "PASS" : "FAIL") + ": " + results.Count + " shared fixtures via actual app loader");
        return passed ? 0 : 1;
    }
}
