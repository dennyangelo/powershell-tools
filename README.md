# powershell-tools

Custom Terminal commands to easily download YouTube videos & audio in the highest available quality, and view your system's current hardware specifications.

---

## Quick Start (For Beginners)

Not super technical? No problem! This toolkit lets you download ad-free YouTube videos/audio directly to your PC and check your system specs using simple terminal commands.

### How to use it:
1. Press your **Windows Key**, type **PowerShell**, and open it. -- Make sure you open Terminal, or Powershell. And not Windows CMD!
2. Run the **Quick Installation** command once (see below).
3. After that, you can use these commands anywhere:
   - **`specs`** -> View your system's hardware specifications.
   - **`download mp4 <link>`** -> Download video with audio.
   - **`download mp3 <link>`** -> Download audio only.

### Examples:
```powershell
download mp4 https://www.youtube.com/watch?v=Z81wUUjPsqM
download mp3 https://www.youtube.com/watch?v=Z81wUUjPsqM
```

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

## Quick Uninstallation
```powershell
irm "https://raw.githubusercontent.com/dennyangelo/powershell-tools/main/uninstall_powershell_commands.ps1" | iex
```

Suggestions are welcome! If you have ideas for any commands that improve QOL, suggest them and I'll add it! Feel free to open an issue or leave your suggestions on the GitHub Issues page.
