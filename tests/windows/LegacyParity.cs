using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Runtime.Serialization;
using System.Web.Script.Serialization;

internal static class LegacyParity
{
    private static int Main(string[] args)
    {
        var serializer = new JavaScriptSerializer();
        Assembly assembly = Assembly.LoadFrom(args[0]);
        Type deckType = assembly.GetType("Cued.CueDeck", true);
        Type windowType = assembly.GetType("Cued.CueDeckWindow", true);
        object window = FormatterServices.GetUninitializedObject(windowType);
        MethodInfo validate = windowType.GetMethod("ValidateDeck", BindingFlags.Instance | BindingFlags.NonPublic);
        var manifest = serializer.Deserialize<Dictionary<string, object>>(File.ReadAllText(Path.Combine(args[1], "manifest.json")));
        var results = new List<object>();
        foreach (Dictionary<string, object> item in (System.Collections.ArrayList)manifest["cases"])
        {
            string file = (string)item["file"];
            bool valid;
            string error = null;
            try
            {
                object deck = serializer.Deserialize(File.ReadAllText(Path.Combine(args[1], file)), deckType);
                error = (string)validate.Invoke(window, new object[] { deck });
                valid = error == null;
            }
            catch (Exception ex) { valid = false; error = ex.GetBaseException().Message; }
            results.Add(new { file = file, expected = (bool)item["valid"], actual = valid, agrees = (bool)item["valid"] == valid, error = error });
        }
        File.WriteAllText(args[2], serializer.Serialize(new { platform = "windows-1.0-loader-baseline", results = results }));
        Console.WriteLine("Baseline recorded: " + results.Count + " cases");
        return 0;
    }
}
