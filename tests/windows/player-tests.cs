using System;
using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;
using System.Web.Script.Serialization;
using System.Collections.Generic;

public static class PlayerTests
{
    private static object Call(object target, string name, params object[] args)
    { return target.GetType().GetMethod(name, BindingFlags.Instance | BindingFlags.NonPublic).Invoke(target, args); }
    private static T Field<T>(object target, string name)
    { return (T)target.GetType().GetField(name, BindingFlags.Instance | BindingFlags.NonPublic).GetValue(target); }
    private static void Check(bool passed, string name)
    { if (!passed) throw new Exception(name); results.Add(name); }
    private static readonly List<string> results = new List<string>();
    private static void Pump()
    {
        DispatcherFrame frame = new DispatcherFrame();
        DispatcherTimer timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(450) };
        timer.Tick += delegate { timer.Stop(); frame.Continue = false; };
        timer.Start(); Dispatcher.PushFrame(frame);
    }

    [STAThread]
    public static int Main(string[] args)
    {
        try
        {
            Environment.SetEnvironmentVariable("CUED_SETTINGS_PATH", Path.Combine(args[1], "isolated-player-settings.json"));
            Directory.CreateDirectory(args[1]);
            Assembly app = Assembly.LoadFrom(Path.GetFullPath(args[0]));
            Type type = app.GetType("Cued.CueDeckWindow");
            Window window = (Window)Activator.CreateInstance(type, new object[] { new string[0] });
            string sample = Path.GetFullPath(Path.Combine(args[2], "valid", "sample.cued.json"));
            string minimum = Path.GetFullPath(Path.Combine(args[2], "valid", "minimum.cued.json"));
            Call(window, "LoadDeck", sample);
            Check(Field<int>(window, "_currentIndex") == 0, "sample starts on first card");
            Call(window, "MoveTo", 2, false);
            Call(window, "MoveTo", 1, false);
            Check(Field<int>(window, "_currentIndex") == 1, "back traversal retains expected card");
            Call(window, "MoveTo", 3, false);
            Call(window, "Advance");
            Check(Field<object>(window, "_deck") == null, "final advance returns to landing");
            Call(window, "LoadDeck", sample);
            Call(window, "MoveTo", 3, true);
            Call(window, "LoadDeck", minimum);
            Pump();
            Check(Field<int>(window, "_currentIndex") == 0 && !Field<bool>(window, "_isTransitioning"), "new shorter deck cancels pending animation");
            Check(Field<Button>(window, "_dropButton").IsEnabled, "next remains enabled after cancellation");
            Call(window, "SetGhostMode", true);
            Check(Field<bool>(window, "_ghostMode") && Field<Button>(window, "_ghostButton").IsEnabled, "ghost control remains enabled");
            Call(window, "ShowLanding");
            Check(!Field<bool>(window, "_ghostMode"), "landing resets ghost mode");
            string before = File.ReadAllText(sample);
            Call(window, "LoadDeck", sample);
            Call(window, "ShowLanding");
            Check(before == File.ReadAllText(sample), "playback leaves deck bytes unchanged");
            var shared = app.GetType("CuedShared.ProviderHandoff");
            string folder = Path.Combine(args[1], "Cued é space");
            string prompt = (string)shared.GetMethod("Prompt").Invoke(null, new object[] { folder });
            Check(prompt.Contains(Path.Combine(folder, "Decks")) && prompt.Contains(Path.Combine(folder, "Cued.exe")), "prompt includes actual spaced Unicode destinations");
            Check(!prompt.Contains("GPT-") && !prompt.Contains("Work mode"), "prompt has no model or mode requirement");
            foreach (bool claude in new[] { false, true })
            {
                string link = (string)shared.GetMethod("Link").Invoke(null, new object[] { claude, folder });
                Check(Uri.UnescapeDataString(link).Contains(prompt), "provider link preserves prepared prompt: " + claude);
            }
            window.Show(); Pump();
            Rect workArea = SystemParameters.WorkArea;
            double savedWidth = Math.Min(480, workArea.Width), savedHeight = Math.Min(680, workArea.Height);
            double savedLeft = workArea.Left + Math.Min(60, workArea.Width - savedWidth);
            double savedTop = workArea.Top + Math.Min(80, workArea.Height - savedHeight);
            window.Width = savedWidth; window.Height = savedHeight; window.Left = savedLeft; window.Top = savedTop;
            window.Close();
            string settingsJson = File.ReadAllText(Environment.GetEnvironmentVariable("CUED_SETTINGS_PATH"));
            Check(!settingsJson.Contains("Infinity") && !settingsJson.Contains("NaN"), "normal close persists finite JSON geometry");
            Window reopened = (Window)Activator.CreateInstance(type, new object[] { new string[0] });
            Check(Field<object>(reopened, "_deck") == null, "reopen does not restore an active deck");
            reopened.Show(); Pump();
            Check(Math.Abs(reopened.Left - savedLeft) < 1 && Math.Abs(reopened.Top - savedTop) < 1 && Math.Abs(reopened.Width - savedWidth) < 1 && Math.Abs(reopened.Height - savedHeight) < 1, "reopen restores saved window geometry within the available desktop");
            reopened.Close();
            Console.WriteLine(new JavaScriptSerializer().Serialize(new { passed = true, checks = results, workArea = workArea.ToString(), savedGeometry = new[] { savedLeft, savedTop, savedWidth, savedHeight }, note = "Programmatic WPF logic tests; not interactive UI acceptance." }));
            return 0;
        }
        catch (Exception ex) { Console.Error.WriteLine(ex); return 1; }
    }
}
