using System;
using System.IO;

namespace CuedShared
{
    // A handoff prepares text. Only the user can install a skill or send a request.
    public static class ProviderHandoff
    {
        public static string Prompt(string appFolder)
        {
            return "Use the installed make-cued-deck skill to prepare Cued speaking cards. " +
                "If the skill is unavailable, explain how to install the included skill package first. " +
                "Ask what I am preparing for if needed. Save the validated .cued.json deck in \"" +
                Path.Combine(appFolder, "Decks") + "\". " +
                "If authorised desktop control is available, open \"" + Path.Combine(appFolder, "Cued.exe") +
                "\" with the deck path as one argument and verify the window. Otherwise return the file for me to open in Cued.";
        }

        public static string Link(bool claude, string appFolder)
        {
            return claude
                ? "claude://cowork/new?q=" + Uri.EscapeDataString(Prompt(appFolder)) + "&folder=" + Uri.EscapeDataString(appFolder)
                : "codex://threads/new?prompt=" + Uri.EscapeDataString(Prompt(appFolder)) + "&path=" + Uri.EscapeDataString(appFolder);
        }
    }
}
