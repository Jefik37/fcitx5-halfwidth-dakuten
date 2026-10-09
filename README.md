# fcitx5-halfwidth-dakuten

A tiny [fcitx5](https://github.com/fcitx/fcitx5) addon that commits halfwidth katakana with the **combining** dakuten/handakuten instead of the spacing halfwidth ones.

| Typed with the IME | Committed by default | Committed with this addon |
|---|---|---|
| ﾀﾞﾝﾎﾞｰﾙ | ﾀﾞﾝﾎﾞｰﾙ `U+FF80 U+FF9E …` | ﾀ゙ﾝﾎ゙ｰﾙ `U+FF80 U+3099 …` |
| ﾊﾟﾝ | ﾊﾟﾝ `U+FF8A U+FF9F …` | ﾊ゚ﾝ `U+FF8A U+309A …` |

It works with any input method (Mozc, Anthy, SKK, …), because it rewrites the text at the moment fcitx5 commits it to the application.

## Why

Mozc, like almost every Japanese IME, writes a voiced halfwidth kana as two characters: the kana plus `U+FF9E HALFWIDTH KATAKANA VOICED SOUND MARK` (or `U+FF9F` for handakuten). Those marks are spacing characters, so every voiced kana takes two cells and the mark floats next to the letter instead of sitting on it.

Unicode already treats them as the narrow form of the combining marks: the compatibility decomposition of `U+FF9E` is `<narrow> U+3099` and that of `U+FF9F` is `<narrow> U+309A`. Mark Davis wrote in [L2/06-246](https://www.unicode.org/L2/L2006/06246-halfwidth.html) that the halfwidth marks *should have been* combining characters in the first place. Committing `U+3099`/`U+309A` puts the mark on the kana, as with fullwidth text.

Mozc has no setting for this. Its halfwidth table (`data/preedit/fullwidthkatakana-halfwidthkatakana.tsv`) is compiled into the binary, so changing it there means rebuilding `fcitx5-mozc` on every update.

## How it works

[fcitx5-lua](https://github.com/fcitx/fcitx5-lua) exposes fcitx5's commit filter through `fcitx.addConverter()`: a Lua function that receives every committed string and may return a replacement. `halfwidthdakuten.lua` registers one that replaces `U+FF9E` with `U+3099` and `U+FF9F` with `U+309A`, but only when the mark directly follows a halfwidth katakana letter (`U+FF66`–`U+FF9D`). A mark typed on its own stays as it is, because a combining mark would otherwise attach to whatever character precedes it.

Text without halfwidth marks takes a single `string.find` and is returned untouched.

## Install

### 1. Install fcitx5-lua

fcitx5 can only run Lua addons once its Lua support is installed:

| Distribution | Command |
|---|---|
| Arch, CachyOS, EndeavourOS, Manjaro | `sudo pacman -S fcitx5-lua` |
| Debian, Ubuntu | `sudo apt install fcitx5-module-lua` |
| Fedora | `sudo dnf install fcitx5-lua` |

### 2. Put the two files in place

A Lua addon is made of two files inside fcitx5's data directory:

- `halfwidthdakuten.conf` goes in `addon/`. The file name, minus `.conf`, becomes the addon's name.
- `halfwidthdakuten.lua` goes in `lua/<addon name>/`. Its file name must match the `Library=` line of the `.conf`.

For your user only, that directory is `~/.local/share/fcitx5` (or `$XDG_DATA_HOME/fcitx5` if you set that variable). From this repository, run:

```sh
mkdir -p ~/.local/share/fcitx5/addon ~/.local/share/fcitx5/lua/halfwidthdakuten
cp halfwidthdakuten.conf ~/.local/share/fcitx5/addon/
cp halfwidthdakuten.lua  ~/.local/share/fcitx5/lua/halfwidthdakuten/
```

You should end up with:

```
~/.local/share/fcitx5/
├── addon/
│   └── halfwidthdakuten.conf
└── lua/
    └── halfwidthdakuten/
        └── halfwidthdakuten.lua
```

To install for every user instead, use the same layout under `/usr/share/fcitx5/` (with `sudo`).

### 3. Restart fcitx5

fcitx5 only looks for addons when it starts, so restart it. Pick *Restart* in the fcitx5 tray menu, or run `fcitx5 -rd`.

On Plasma Wayland, fcitx5 may have been started by KWin (System Settings → Keyboard → Virtual Keyboard → Fcitx 5). In that case it refuses to restart itself; toggle that setting off and on again, or log out and back in.

## Checking that it works

Run `od` in a terminal and switch Mozc to halfwidth katakana (or convert with F8). Type `ﾀﾞ`, then press Enter and Ctrl+D:

```sh
od -An -tx1
```

With the addon the output is ` ef be 80 e3 82 99 0a` (the combining `U+3099`). Without it you get ` ef be 80 ef be 9e 0a` (the halfwidth `U+FF9E`).

If fcitx5 runs as a systemd user service (which is the default for XDG autostart on most desktops), its log also shows the addon:

```sh
journalctl --user -b | grep 'Loaded addon halfwidthdakuten'
```

## Disabling and uninstalling

- **Disable temporarily:** open fcitx5-configtool → *Addons* and untick *Halfwidth Dakuten*.
- **Uninstall:** delete the two files from step 2 and restart fcitx5, which can't unload an addon while running.

## Limitations

- **Only committed text is rewritten.** The preedit and the candidate window still show `ﾞ` while you type, because fcitx5-lua has no hook for fcitx5's output filter (that one is C++ only).
- **The kana and its mark must arrive in the same commit.** With Mozc they always do.
- **The text is not byte-identical to the usual form.** Searching for `ﾀﾞﾝﾎﾞｰﾙ` won't find `ﾀ゙ﾝﾎ゙ｰﾙ` unless the search normalizes: NFKC turns both into `ダンボール`.
- **Rendering depends on the font and the application.** Some editors draw combining kana marks poorly ([sakura-editor#1938](https://github.com/sakura-editor/sakura/issues/1938)). In terminals, `U+3099` has zero width, so `ﾀ゙` takes one cell where `ﾀﾞ` took two.

## Development

The tests run the converter outside fcitx5 with a stub `fcitx` module (needs Lua 5.3 or newer):

```sh
lua tests/test.lua halfwidthdakuten.lua
```

### Alternatives considered

- **Patching Mozc.** Swap the marks in `fullwidthkatakana-halfwidthkatakana.tsv` and adjust the reverse table, then rebuild `fcitx5-mozc` with Bazel after every update. That changes the preedit too, but it is far too heavy to maintain.
- **A C++ fcitx5 module.** It would connect to both `Instance::CommitFilter` and `Instance::OutputFilter`, like the `chttrans` module in fcitx5-chinese-addons, so the preedit and candidates would change as well. The swap keeps byte offsets valid because both marks are 3 bytes in UTF-8. The cost is that it has to be compiled against each fcitx5 release.

## References

- Unicode [L2/06-246](https://www.unicode.org/L2/L2006/06246-halfwidth.html): halfwidth voice marks in Grapheme_Extend
- Unicode [L2/19-039](https://www.unicode.org/L2/L2019/19039-grapheme-brk-prop.html): grapheme break property of `U+FF9E`/`U+FF9F`
- fcitx5-lua API: [`fcitx` module](https://fcitx.github.io/fcitx5-lua/modules/fcitx.html), and the [Fcitx wiki page on Lua](https://fcitx-im.org/wiki/Lua)
