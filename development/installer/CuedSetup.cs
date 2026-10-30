using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows.Forms;

[assembly: AssemblyTitle("Cued Setup")]
[assembly: AssemblyProduct("Cued")]
[assembly: AssemblyDescription("Installs the Cued speaking-card player")]
[assembly: AssemblyVersion("1.1.0.0")]
[assembly: AssemblyFileVersion("1.1.0.0")]

namespace CuedSetup
{
    internal sealed class SetupForm : Form
    {
        private static readonly Color Page = Color.FromArgb(24, 24, 24);
        private static readonly Color Surface = Color.FromArgb(34, 34, 34);
        private static readonly Color Line = Color.FromArgb(64, 64, 64);
        private static readonly Color TextColour = Color.FromArgb(244, 244, 242);
        private static readonly Color Muted = Color.FromArgb(174, 173, 169);
        private static readonly Color Accent = Color.FromArgb(238, 116, 79);

        private readonly string _packageRoot;
        private readonly TextBox _destination;
        private readonly CheckBox _desktopShortcut;
        private readonly CheckBox _startShortcut;
        private readonly CheckBox _openAiSkill;
        private readonly CheckBox _launchCued;
        private readonly CheckBox _openChatGpt;
        private readonly CheckBox _openClaude;
        private readonly Button _installButton;
        private readonly Label _status;

        public SetupForm(string packageRoot)
        {
            _packageRoot = packageRoot;

            Text = "Set up Cued";
            ClientSize = new Size(690, 675);
            MinimumSize = new Size(690, 675);
            MaximumSize = new Size(880, 840);
            StartPosition = FormStartPosition.CenterScreen;
            BackColor = Page;
            ForeColor = TextColour;
            Font = new Font("Segoe UI", 10F, FontStyle.Regular, GraphicsUnit.Point);
            AutoScaleMode = AutoScaleMode.Dpi;

            Label brand = NewLabel("Cued", 29F, FontStyle.Bold);
            brand.Location = new Point(42, 30);
            brand.AutoSize = true;
            Controls.Add(brand);

            Label strapline = NewLabel("Speaking cards without the script", 11F, FontStyle.Regular);
            strapline.ForeColor = Accent;
            strapline.Location = new Point(45, 77);
            strapline.AutoSize = true;
            Controls.Add(strapline);

            Label intro = NewLabel(
                "Choose where Cued lives and which shortcuts you want. Everything installs for this Windows account only.",
                10.5F,
                FontStyle.Regular);
            intro.ForeColor = Muted;
            intro.Location = new Point(45, 116);
            intro.Size = new Size(590, 44);
            Controls.Add(intro);

            Label destinationLabel = NewLabel("Install Cued in", 10F, FontStyle.Bold);
            destinationLabel.Location = new Point(45, 171);
            destinationLabel.AutoSize = true;
            Controls.Add(destinationLabel);

            _destination = new TextBox();
            _destination.Location = new Point(45, 199);
            _destination.Size = new Size(500, 29);
            _destination.Text = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                "Cued");
            _destination.BackColor = Surface;
            _destination.ForeColor = TextColour;
            _destination.BorderStyle = BorderStyle.FixedSingle;
            Controls.Add(_destination);

            Button browse = NewButton("Browse…", 99, 31);
            browse.Location = new Point(557, 197);
            browse.Click += BrowseForDestination;
            Controls.Add(browse);

            Panel options = new Panel();
            options.Location = new Point(45, 252);
            options.Size = new Size(600, 288);
            options.BackColor = Surface;
            options.BorderStyle = BorderStyle.FixedSingle;
            Controls.Add(options);

            _desktopShortcut = NewCheckBox("Add Cued to the Desktop", true, 14);
            options.Controls.Add(_desktopShortcut);

            _startShortcut = NewCheckBox("Add Cued to the Start menu", true, 50);
            options.Controls.Add(_startShortcut);

            Label pinNote = NewLabel("From Start, right-click Cued to pin it to the taskbar.", 8.75F, FontStyle.Regular);
            pinNote.ForeColor = Muted;
            pinNote.Location = new Point(49, 88);
            pinNote.AutoSize = true;
            options.Controls.Add(pinNote);

            _openAiSkill = NewCheckBox("Install the Cued skill for ChatGPT and Codex", true, 112);
            options.Controls.Add(_openAiSkill);

            _launchCued = NewCheckBox("Open Cued when setup finishes", true, 152);
            options.Controls.Add(_launchCued);

            _openChatGpt = NewCheckBox("Open ChatGPT with a Cued prompt", false, 192);
            _openChatGpt.CheckedChanged += delegate
            {
                if (_openChatGpt.Checked) _openAiSkill.Checked = true;
            };
            options.Controls.Add(_openChatGpt);

            _openClaude = NewCheckBox("Show the Claude skill ZIP when setup finishes", false, 232);
            options.Controls.Add(_openClaude);

            _status = NewLabel("", 9F, FontStyle.Regular);
            _status.ForeColor = Muted;
            _status.Location = new Point(45, 558);
            _status.Size = new Size(450, 35);
            Controls.Add(_status);

            _installButton = NewButton("Install Cued", 150, 46);
            _installButton.Location = new Point(495, 553);
            _installButton.BackColor = Accent;
            _installButton.ForeColor = Color.FromArgb(23, 17, 15);
            _installButton.FlatAppearance.BorderColor = Accent;
            _installButton.Font = new Font("Segoe UI", 10.5F, FontStyle.Bold);
            _installButton.Click += Install;
            Controls.Add(_installButton);

            Label trust = NewLabel(
                "Note: Cued is not code-signed, so Windows may show a SmartScreen warning.",
                8.75F,
                FontStyle.Regular);
            trust.ForeColor = Muted;
            trust.Location = new Point(45, 631);
            trust.Size = new Size(600, 30);
            Controls.Add(trust);
        }

        private Label NewLabel(string value, float size, FontStyle style)
        {
            Label label = new Label();
            label.Text = value;
            label.Font = new Font("Segoe UI", size, style, GraphicsUnit.Point);
            label.ForeColor = TextColour;
            label.BackColor = Color.Transparent;
            return label;
        }

        private Button NewButton(string value, int width, int height)
        {
            Button button = new Button();
            button.Text = value;
            button.Size = new Size(width, height);
            button.BackColor = Surface;
            button.ForeColor = TextColour;
            button.FlatStyle = FlatStyle.Flat;
            button.FlatAppearance.BorderColor = Line;
            button.Cursor = Cursors.Hand;
            return button;
        }

        private CheckBox NewCheckBox(string value, bool isChecked, int top)
        {
            CheckBox check = new CheckBox();
            check.Tag = value;
            check.Appearance = Appearance.Button;
            check.AutoSize = false;
            check.Size = new Size(562, 34);
            check.Location = new Point(18, top);
            check.TextAlign = ContentAlignment.MiddleLeft;
            check.Padding = new Padding(10, 0, 0, 0);
            check.BackColor = Surface;
            check.FlatStyle = FlatStyle.Flat;
            check.FlatAppearance.BorderSize = 0;
            check.FlatAppearance.CheckedBackColor = Color.FromArgb(54, 54, 54);
            check.FlatAppearance.MouseOverBackColor = Color.FromArgb(46, 46, 46);
            check.Cursor = Cursors.Hand;
            check.UseVisualStyleBackColor = false;
            check.CheckedChanged += UpdateToggleAppearance;
            check.Checked = isChecked;
            UpdateToggleAppearance(check, EventArgs.Empty);
            return check;
        }

        private void UpdateToggleAppearance(object sender, EventArgs e)
        {
            CheckBox check = sender as CheckBox;
            if (check == null) return;

            string label = Convert.ToString(check.Tag);
            check.Text = (check.Checked ? "\u2713  " : "\u25CB  ") + label;
            check.ForeColor = check.Checked ? TextColour : Muted;
        }

        private void BrowseForDestination(object sender, EventArgs e)
        {
            using (FolderBrowserDialog dialog = new FolderBrowserDialog())
            {
                dialog.Description = "Choose the folder where Cued should be installed.";
                dialog.SelectedPath = Directory.Exists(_destination.Text)
                    ? _destination.Text
                    : Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
                dialog.ShowNewFolderButton = true;
                if (dialog.ShowDialog(this) == DialogResult.OK)
                {
                    _destination.Text = dialog.SelectedPath;
                }
            }
        }

        private void Install(object sender, EventArgs e)
        {
            string destination;
            try
            {
                destination = Path.GetFullPath(Environment.ExpandEnvironmentVariables(_destination.Text.Trim()));
            }
            catch
            {
                ShowError("Choose a valid installation folder.");
                return;
            }

            if (string.IsNullOrWhiteSpace(_destination.Text))
            {
                ShowError("Choose where Cued should be installed.");
                return;
            }

            string appSource = Path.Combine(_packageRoot, "app");
            string skillSource = Path.Combine(_packageRoot, "source", "make-cued-deck");
            string claudePackage = Path.Combine(_packageRoot, "packages", "make-cued-deck-claude.zip");

            if (!File.Exists(Path.Combine(appSource, "Cued.exe")) ||
                !File.Exists(Path.Combine(skillSource, "SKILL.md")) ||
                !File.Exists(claudePackage))
            {
                ShowError("The Cued setup files are incomplete. Keep CuedSetup.exe beside the app, source and packages folders.");
                return;
            }

            _installButton.Enabled = false;
            _status.Text = "Installing…";
            Refresh();

            try
            {
                if (string.Equals(Path.GetFullPath(appSource).TrimEnd(Path.DirectorySeparatorChar), destination.TrimEnd(Path.DirectorySeparatorChar), StringComparison.OrdinalIgnoreCase))
                    throw new InvalidOperationException("Choose a separate installation folder, not the package's app folder.");
                Directory.CreateDirectory(destination);
                CopyDirectory(appSource, destination);

                string installedSkills = Path.Combine(destination, "Skills");
                Directory.CreateDirectory(installedSkills);
                string installedClaudeZip = Path.Combine(installedSkills, "make-cued-deck-claude.zip");
                File.Copy(
                    claudePackage,
                    installedClaudeZip,
                    true);

                Directory.CreateDirectory(Path.Combine(destination, "Decks"));
                File.WriteAllText(Path.Combine(destination, "Create a Cued deck.txt"),
                    "Install the included skill in your AI tool first. Copy the prompt below, review it and send it yourself. A link does not install a skill or send a request.\r\n\r\n" + CuedShared.ProviderHandoff.Prompt(destination));
                string guide = Path.Combine(_packageRoot, "QUICK-START.md");
                if (File.Exists(guide)) File.Copy(guide, Path.Combine(destination, "QUICK-START.md"), true);
                string installedExe = Path.Combine(destination, "Cued.exe");
                string chatGptLink = BuildChatGptLink(destination);

                WriteInternetShortcut(
                    Path.Combine(destination, "Open ChatGPT with Cued.url"),
                    chatGptLink,
                    installedExe);

                if (_openAiSkill.Checked)
                {
                    string personalSkill = Path.Combine(
                        Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                        ".agents",
                        "skills",
                        "make-cued-deck");
                    CopyDirectory(skillSource, personalSkill);
                }

                if (_desktopShortcut.Checked)
                {
                    string desktop = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
                    CreateShortcut(Path.Combine(desktop, "Cued.lnk"), installedExe, destination);
                }

                if (_startShortcut.Checked)
                {
                    string startFolder = Path.Combine(
                        Environment.GetFolderPath(Environment.SpecialFolder.StartMenu),
                        "Programs",
                        "Cued");
                    Directory.CreateDirectory(startFolder);
                    CreateShortcut(Path.Combine(startFolder, "Cued.lnk"), installedExe, destination);
                }

                _status.Text = "Cued is installed.";

                if (_openChatGpt.Checked) OpenLink(chatGptLink);
                if (_openClaude.Checked)
                {
                    Process.Start(
                        new ProcessStartInfo(
                            "explorer.exe",
                            "/select,\"" + installedClaudeZip + "\"")
                        {
                            UseShellExecute = true
                        });
                }
                if (_launchCued.Checked)
                {
                    Process.Start(new ProcessStartInfo(installedExe) { UseShellExecute = true });
                }

                MessageBox.Show(
                    this,
                    "Cued is ready.\n\nInstalled in:\n" + destination +
                    "\n\nThe Claude skill package is in the Skills folder.",
                    "Cued setup",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                ShowError("Cued could not be installed.\n\n" + ex.Message);
            }
            finally
            {
                _installButton.Enabled = true;
            }
        }

        private static void CopyDirectory(string source, string destination)
        {
            Directory.CreateDirectory(destination);
            foreach (string file in Directory.GetFiles(source))
            {
                string fileName = Path.GetFileName(file);
                if (fileName.EndsWith(".pyc", StringComparison.OrdinalIgnoreCase)) continue;
                File.Copy(file, Path.Combine(destination, fileName), true);
            }

            foreach (string directory in Directory.GetDirectories(source))
            {
                string name = Path.GetFileName(directory);
                if (name.Equals("__pycache__", StringComparison.OrdinalIgnoreCase)) continue;
                CopyDirectory(directory, Path.Combine(destination, name));
            }
        }

        private static string BuildChatGptLink(string appFolder)
        {
            return CuedShared.ProviderHandoff.Link(false, appFolder);
        }

        private static void OpenLink(string value)
        {
            Process.Start(new ProcessStartInfo(value) { UseShellExecute = true });
        }

        private static void WriteInternetShortcut(string path, string url, string icon)
        {
            File.WriteAllText(
                path,
                "[InternetShortcut]\r\nURL=" + url + "\r\nIconFile=" + icon + "\r\nIconIndex=0\r\n");
        }

        private static void CreateShortcut(string shortcutPath, string targetPath, string workingDirectory)
        {
            Type shellType = Type.GetTypeFromProgID("WScript.Shell");
            if (shellType == null) throw new InvalidOperationException("Windows shortcut support is unavailable.");

            object shell = null;
            object shortcut = null;
            try
            {
                shell = Activator.CreateInstance(shellType);
                shortcut = shellType.InvokeMember(
                    "CreateShortcut",
                    System.Reflection.BindingFlags.InvokeMethod,
                    null,
                    shell,
                    new object[] { shortcutPath });
                Type shortcutType = shortcut.GetType();
                shortcutType.InvokeMember("TargetPath", System.Reflection.BindingFlags.SetProperty, null, shortcut, new object[] { targetPath });
                shortcutType.InvokeMember("WorkingDirectory", System.Reflection.BindingFlags.SetProperty, null, shortcut, new object[] { workingDirectory });
                shortcutType.InvokeMember("IconLocation", System.Reflection.BindingFlags.SetProperty, null, shortcut, new object[] { targetPath + ",0" });
                shortcutType.InvokeMember("Description", System.Reflection.BindingFlags.SetProperty, null, shortcut, new object[] { "Open Cued speaking cards" });
                shortcutType.InvokeMember("Save", System.Reflection.BindingFlags.InvokeMethod, null, shortcut, null);
            }
            finally
            {
                if (shortcut != null && Marshal.IsComObject(shortcut)) Marshal.FinalReleaseComObject(shortcut);
                if (shell != null && Marshal.IsComObject(shell)) Marshal.FinalReleaseComObject(shell);
            }
        }

        private void ShowError(string message)
        {
            _status.Text = "Setup needs attention.";
            MessageBox.Show(this, message, "Cued setup", MessageBoxButtons.OK, MessageBoxIcon.Warning);
        }
    }

    internal static class Program
    {
        [STAThread]
        private static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            string packageRoot = AppDomain.CurrentDomain.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar);
            Application.Run(new SetupForm(packageRoot));
        }
    }
}
