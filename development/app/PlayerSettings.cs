using System;
using System.IO;
using System.Web.Script.Serialization;

namespace Cued
{
    public sealed class PlayerSettings
    {
        public double TextSize { get; set; }
        public double GhostOpacity { get; set; }
        public bool ReducedMotion { get; set; }
        public double Left { get; set; }
        public double Top { get; set; }
        public double Width { get; set; }
        public double Height { get; set; }

        public PlayerSettings() { TextSize = 20; GhostOpacity = .9; Left = double.NaN; Top = double.NaN; Width = 520; Height = 790; }
        private static string SettingsPath
        {
            get { return Environment.GetEnvironmentVariable("CUED_SETTINGS_PATH") ?? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Cued", "settings.json"); }
        }
        public static PlayerSettings Load()
        {
            try
            {
                if (!File.Exists(SettingsPath)) return new PlayerSettings();
                var settings = new JavaScriptSerializer().Deserialize<PlayerSettings>(File.ReadAllText(SettingsPath));
                if (settings == null) return new PlayerSettings();
                settings.TextSize = Clamp(settings.TextSize, 17, 26, 20);
                settings.GhostOpacity = Clamp(settings.GhostOpacity, .65, 1, .9);
                settings.Width = Clamp(settings.Width, 420, 4000, 520);
                settings.Height = Clamp(settings.Height, 400, 4000, 790);
                return settings;
            }
            catch { return new PlayerSettings(); }
        }
        private static double Clamp(double value, double min, double max, double fallback)
        { return double.IsNaN(value) || double.IsInfinity(value) ? fallback : Math.Max(min, Math.Min(max, value)); }
        public void Save()
        {
            try
            {
                // Never persist WPF's unset/closed-window infinities as invalid JSON.
                Left = Clamp(Left, -100000, 100000, 0);
                Top = Clamp(Top, -100000, 100000, 0);
                Width = Clamp(Width, 420, 4000, 520);
                Height = Clamp(Height, 400, 4000, 790);
                var path = SettingsPath;
                Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path)));
                var temporary = path + ".tmp";
                File.WriteAllText(temporary, new JavaScriptSerializer().Serialize(this));
                if (File.Exists(path)) File.Replace(temporary, path, null); else File.Move(temporary, path);
            }
            catch { /* A read-only settings folder must not prevent playback or closing. */ }
        }
    }
}
