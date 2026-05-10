# Post-install setup

After the first successful boot of `sloane`, work through this list. These
are imperative steps that can't be expressed in the Nix configuration —
secrets, accounts, online service tokens, hardware-specific settings.

Some are essential (do them first); others can wait until you actually
need the feature.

## Essential (do these first)

### 1. Change the initial password

The Nix config sets `initialPassword = "changeme"` for matthew. The
hash is committed to git, so it's effectively public. Rotate it now:

```bash
passwd
```

Pick something strong. Stored only in `/etc/shadow` afterwards.

### 2. Disable password SSH (after key setup)

The OpenSSH module currently allows `PasswordAuthentication = true` so
you can recover access if needed. Once you're set up, switch to
key-based auth only.

First, set up SSH keys (see step 4 below). Once you can log in via
`ssh matthew@sloane` from another machine **using a key, not a
password**, switch the option in `modules/nixos/services/openssh.nix`:

```nix
services.openssh.settings.PasswordAuthentication = false;
```

Rebuild. Verify you can still log in remotely. If you can't, log in
locally, flip back, fix what's wrong.

### 3. Set up Noctalia coordination with Stylix

Noctalia and Stylix both want to write to gsettings. Without this
step, they fight and gsettings ends up inconsistent.

Open Noctalia's settings (click the gear icon in the bar, or hit
`Mod+D` and search "settings"). Navigate to **Color Schemes**.

Toggle:
- **Sync GSettings**: ON → **OFF**

Stylix now owns gsettings/GTK theming. Noctalia continues to theme
its own UI via its built-in `predefinedScheme: "Catppuccin"`.

Alternatively, edit the JSON directly (Noctalia must be closed):

```bash
sed -i 's/"syncGsettings": true/"syncGsettings": false/' \
    ~/.config/noctalia/settings.json
```

### 4. Set up SSH keys for git (and remote access)

Generate an Ed25519 keypair:

```bash
ssh-keygen -t ed25519 -C "matthew@kith.us"
# Press Enter to accept default path: ~/.ssh/id_ed25519
# Pick a strong passphrase (or skip if you use ssh-agent)
```

The flake's `programs.git.signing.key` already references
`~/.ssh/id_ed25519.pub`. Once the key exists, commit signing
works automatically.

Add the public key to GitHub:

```bash
cat ~/.ssh/id_ed25519.pub
# Paste into:
# https://github.com/settings/keys (Authentication keys)
# https://github.com/settings/ssh/new (Signing keys — same key, different list)
```

Verify with a test commit:

```bash
cd ~/code/nixos-config
echo "# test" >> /tmp/test
git add /tmp/test  # won't actually be added since it's outside the repo
# Easier test: just run
git log --show-signature -1
# After your next commit, GitHub will show "Verified" badge
```

## Configuration of services

### 5. Configure Proton Drive sync via rclone

The `rclone` package is installed. Configure a Proton Drive remote:

```bash
rclone config
```

Follow the interactive prompts:
- `n` for new remote
- Name: `protondrive` (or whatever you prefer)
- Type: `protondrive` (search the list)
- Username: your Proton email
- Password: your Proton password (or 2FA-Mode app password —
  see [Proton's app password docs](https://proton.me/support/password-for-imap-smtp-protonmail-bridge))
- Other questions: defaults are fine for most

Test:

```bash
rclone ls protondrive:
```

Set up periodic sync however you prefer (cron, systemd timer, manual).

### 6. Configure Bitwig Studio license

Bitwig is a paid product. After install:

1. Launch Bitwig
2. Sign in with your Bitwig account
3. License should auto-activate from your account

Bitwig stores its settings under `~/.BitwigStudio/`, not XDG paths,
which is annoying but unchangeable.

### 7. Add LinnStrument settings

Bitwig + LinnStrument MPE workflow:

1. In Bitwig, Settings → Controllers → Add MIDI controller
2. Pick "Generic" → MPE
3. Set the MIDI input to the LinnStrument
4. Configure pitch bend range, etc., per LinnStrument's recommended
   Bitwig settings

LinnStrument firmware updates and config presets are managed via the
LinnStrument editor app on macOS — no Linux equivalent. Check
periodically via the Mac.

### 8. Configure printer (Epson ET-4850)

The printing module installs CUPS with driverless IPP Everywhere
support. The Epson should auto-discover, but to add manually:

1. Open the CUPS web interface: `http://localhost:631`
2. Administration → Add Printer
3. Authenticate with system password
4. Pick the discovered Epson via the network
5. Use "IPP Everywhere" driver (no manufacturer-specific driver needed)

Test with a print job from any GTK app.

For scanning, the `sane-airscan` package is installed and the
`scanner` group is set on matthew. Test with `simple-scan`:

```bash
nix shell nixpkgs#simple-scan -- simple-scan
```

### 9. Verify Brave debloat policies

Brave should respect the policies dropped in
`/etc/brave/policies/managed/policies.json` by the workstation
profile. Verify after launch:

1. Open Brave
2. Navigate to: `brave://policy/`
3. Confirm the policies you expect are listed and "active":
   - `BraveRewardsDisabled` — true
   - `BraveWalletDisabled` — true
   - `BraveVPNDisabled` — true
   - `BraveAIChatEnabled` — false
   - `BraveNewsDisabled` — true
   - `BraveTalkDisabled` — true
   - `TorDisabled` — true
   - `BraveP3AEnabled` — false
   - `BraveStatsPingEnabled` — false
   - `BraveWebDiscoveryEnabled` — false
   - `DnsOverHttpsMode` — "off"

If any are missing, the file's not being read. Check
`/etc/brave/policies/managed/policies.json` exists and is readable.

Sign in to Brave Sync if you use it (the policy keeps Sync available).

## Personalization

### 10. Replace the placeholder wallpaper

Stylix's `image` is currently a solid Catppuccin background color
generated by ImageMagick. Replace with a real wallpaper:

1. Choose an image you like (~3840×2160 ideally for the 4K display).
   Save it to the repo, e.g. `wallpapers/sloane.png`.
2. Edit `modules/nixos/desktop/theming.nix`. Replace:

```nix
   image = pkgs.runCommand "placeholder-wallpaper.png" {} ''
     ${pkgs.imagemagick}/bin/magick -size 3840x2160 xc:'#1e1e2e' $out
   '';
```

   with:

```nix
   image = ../../wallpapers/sloane.png;
```

3. Rebuild. Stylix uses this for the SDDM background and as the
   default desktop wallpaper Noctalia falls back to.
4. Noctalia's wallpaper handler also lets you pick from a directory
   per its settings (`wallpaper.directory`); that overrides the
   Stylix wallpaper for the desktop. The SDDM background still uses
   Stylix's `image`.

### 11. Configure Noctalia to taste

Most of Noctalia's settings are already in good shape from the
snapshot (`users/matthew/noctalia/settings.json.snapshot`). After
first boot, Noctalia uses its own defaults. To restore the
working configuration:

```bash
cp ~/code/nixos-config/users/matthew/noctalia/settings.json.snapshot \
   ~/.config/noctalia/settings.json
```

Then restart Noctalia (kill `qs` and let Niri's spawn-at-startup
relaunch it, or just log out and back in).

After making changes you want to keep, snapshot back:

```bash
cp ~/.config/noctalia/settings.json \
   ~/code/nixos-config/users/matthew/noctalia/settings.json.snapshot
git add users/matthew/noctalia/settings.json.snapshot
git commit -m "chore: snapshot Noctalia settings"
```

### 12. Configure Zed

Zed (when installed) stores config under `~/.config/zed/` and isn't
declaratively managed in this flake yet. Sign in to your Zed account
to sync settings if you use that feature.

Pick keymap (VSCode-style is the default):
- Cmd-Shift-P → "Open Keymap"

## Optional / use-case specific

### 13. Steam: configure Proton-GE

`protonplus` is installed. Use it to manage custom Proton versions:

```bash
protonplus
# Or launch via app menu
```

In its UI, install one or more recent Proton-GE builds. They'll
show up in Steam's compatibility tool list (per-game settings →
Force a specific Steam Play compatibility tool).

For most games: try stock Proton first, fall back to Proton-GE if
something doesn't work.

### 14. Set up yabridge for Windows VST hosting

`yabridge` is installed for running Windows VSTs (e.g., Kontakt) in
Bitwig.

1. Install your Windows VSTs into a wineprefix:

```bash
   # Use winetricks if needed for dependencies
   winetricks --self-update
```

2. Run yabridgectl to bridge them:

```bash
   yabridgectl add ~/.wine/drive_c/Program\ Files/VstPlugins
   yabridgectl sync
```

3. Bitwig should pick up the bridged plugins on next scan.

For Kontakt specifically, see your Native Instruments / Orange Tree
docs — the workflow varies by library.

### 15. Set up Standard Notes

Already installed. On first launch, sign in with your Standard
Notes account. The 5-year license you have unlocks all extensions.

### 16. Configure ProtonVPN

```bash
protonvpn-app  # GUI
# or use systemctl --user start protonvpn-app
```

Sign in. Select a server. The app handles the underlying WireGuard
or OpenVPN config.

## Maintenance

### 17. Update flake periodically

Use the abbreviation:

```bash
nfu   # nix flake update
nrs   # rebuild and switch
```

After updates, verify things still work. If something breaks, see the
rollback section in the README.

### 18. Manual snapshot of Noctalia after meaningful tweaks

When you change Noctalia settings via its GUI in a way you want
preserved across reinstalls or other hosts:

```bash
cp ~/.config/noctalia/settings.json \
   ~/code/nixos-config/users/matthew/noctalia/settings.json.snapshot
git add users/matthew/noctalia/settings.json.snapshot
git commit -m "chore: snapshot Noctalia settings"
git push
```

### 19. Theme experimentation

In `modules/nixos/desktop/theming.nix`, change the `theme` variable
in the `let` block. Available schemes:
- `catppuccin-mocha` (current)
- `catppuccin-frappe`, `catppuccin-macchiato`
- `tokyo-night-dark`, `tokyo-night-storm`
- `rose-pine`, `rose-pine-moon`
- `gruvbox-dark-hard`, `nord`, `dracula`
- `kanagawa`, `everforest`, `oxocarbon-dark`

Full list in the `base16-schemes` package:
```bash
ls $(nix-build '' -A base16-schemes --no-out-link)/share/themes/
```

Rebuild after changing. Most surfaces follow Stylix and update
automatically. Surfaces NOT covered:
- **Noctalia** — change its `predefinedScheme` via Noctalia's GUI
- **SDDM** — already auto-themed by Stylix
- **Brave** — install a Chrome theme matching the new scheme
- **Steam** — `adwsteamgtk` follows GTK theme; should follow Stylix automatically

## Troubleshooting

### SDDM doesn't start / black screen at boot

1. Switch to TTY: `Ctrl+Alt+F2`
2. Log in as matthew
3. Check SDDM status: `sudo systemctl status display-manager`
4. Common issues:
   - Stylix-generated SDDM theme failing → temporarily disable
     `stylix.targets.sddm.enable = false;` and rebuild
   - Wayland session issue → check `~/.local/share/sddm/wayland-session.log`

### Niri fails to start after login

1. SDDM session list includes "Niri"; pick it explicitly if multiple
   sessions exist (default GNOME session might also be available).
2. Check Niri's log: `journalctl --user -u niri.service -e`

### Noctalia bar doesn't appear

Niri spawns Noctalia via `spawn-at-startup`. If it didn't:
```bash
qs -c noctalia-shell &
```

Check why it failed:
```bash
journalctl --user -e | grep -i noctalia
```

### Audio not working

```bash
systemctl --user status pipewire
systemctl --user status wireplumber
```

If both are running but no sound: open `pwvucontrol`, check the
output device is the right one and not muted.

### Brave policies not applying

```bash
ls -la /etc/brave/policies/managed/
cat /etc/brave/policies/managed/policies.json
```

If the file's missing, the workstation profile didn't apply the
`environment.etc."brave/policies/managed/policies.json"` block. Verify
in `modules/nixos/profiles/workstation.nix`.

## What's intentionally not declarative

A few things were left imperative on purpose. Don't try to migrate
them to Nix without thinking through it:

- **Noctalia settings.json** — actively edited via Noctalia's GUI.
  Snapshots in repo; not managed declaratively.
- **Bitwig project files / preferences** — proprietary, stored in
  `~/.BitwigStudio/`. Don't touch from Nix.
- **Browser profiles** (Brave, LibreWolf) — too dynamic, stored locally,
  contain login state.
- **SSH keys** — created via `ssh-keygen`, not generated declaratively.
  Including them in Nix would put them in the world-readable nix store.
- **Wine prefixes** — stateful by nature, contains Windows software.
- **Steam library / compatibility tool selections** — per-game state.

Some of these *could* be made declarative with effort (sops-nix for
secrets, home-manager modules for browser configs). Worth doing only
if the maintenance cost is genuinely paying off.
