# powershell-tools

Custom Terminal commands to easily download YouTube videos & audio in the highest available quality, and view your system's current hardware specifications.

## Usage

- **`specs`**: Displays a clean overview of your hardware specifications (Motherboard, BIOS, CPU, GPU, RAM, and storage with estimated max speeds).
- **`download mp3 <link>`**: Downloads the highest quality audio (`-x --audio-format mp3`) and saves it directly to your Windows **Downloads** folder.
- **`download mp4 <link>`**: Downloads video and audio merged into a universally supported H.264/MP4 format (`bv*[vcodec^=avc]+ba/b`) and saves it directly to your Windows **Downloads** folder.

---

## Quick Installation (One-Liner)

Open **PowerShell as Administrator** and run the following command to automatically download and install everything:

```powershell
irm "https://raw.githubusercontent.com/dennyangelo/powershell-tools/main/setup_powershell_commands.ps1" | iex
```

Suggestions are welcome! If you have ideas for any commands that improve QOL, suggest them and I'll add it! Feel free to open an issue or leave your suggestions on the GitHub Issues page.
