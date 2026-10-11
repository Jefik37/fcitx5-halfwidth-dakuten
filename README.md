# fcitx5-halfwidth-dakuten

A tiny [fcitx5](https://github.com/fcitx/fcitx5) addon that commits halfwidth katakana with the **combining** dakuten/handakuten instead of the spacing halfwidth ones. It works with any input method (Mozc, Anthy, SKK, …).

| Typed | Committed by default | Committed with this addon |
|---|---|---|
| ﾀﾞﾝﾎﾞｰﾙ | ﾀﾞﾝﾎﾞｰﾙ `U+FF80 U+FF9E …` | ﾀ゙ﾝﾎ゙ｰﾙ `U+FF80 U+3099 …` |
| ﾊﾟﾝ | ﾊﾟﾝ `U+FF8A U+FF9F …` | ﾊ゚ﾝ `U+FF8A U+309A …` |

## Why

Mozc, like almost every Japanese IME, writes a voiced halfwidth kana as two characters: the kana plus `U+FF9E` (or `U+FF9F` for handakuten). Those marks are spacing characters, so the mark floats next to the letter instead of sitting on it.

Unicode already treats them as the narrow form of the combining marks (`U+FF9E` decomposes to `<narrow> U+3099`, `U+FF9F` to `<narrow> U+309A`), and [L2/06-246](https://www.unicode.org/L2/L2006/06246-halfwidth.html) says they should have been combining characters in the first place. Mozc has no setting for this: its halfwidth table is compiled into the binary.

## How it works

The addon rewrites the text fcitx5 commits: `U+FF9E`/`U+FF9F` become `U+3099`/`U+309A` when they directly follow a halfwidth katakana letter (`U+FF66`–`U+FF9D`). A mark typed on its own stays as it is, since a combining mark would attach to whatever comes before it.

## Install

Install fcitx5's Lua support:

| Distribution | Command |
|---|---|
| Arch, CachyOS, EndeavourOS, Manjaro | `sudo pacman -S fcitx5-lua` |
| Debian, Ubuntu | `sudo apt install fcitx5-module-lua` |
| Fedora | `sudo dnf install fcitx5-lua` |

Copy the addon (or use `/usr/share/fcitx5/` for every user):

```sh
mkdir -p ~/.local/share/fcitx5/addon ~/.local/share/fcitx5/lua/halfwidthdakuten
cp halfwidthdakuten.conf ~/.local/share/fcitx5/addon/
cp halfwidthdakuten.lua  ~/.local/share/fcitx5/lua/halfwidthdakuten/
```

Restart fcitx5 from its tray menu or with `fcitx5 -rd`. If KWin started it (Plasma Wayland, *Virtual Keyboard* setting), toggle that setting or log out and back in.

To check, run `od -An -tx1` in a terminal, type `ﾀﾞ` in halfwidth katakana (or convert with F8), then press Enter and Ctrl+D. With the addon you get `ef be 80 e3 82 99 0a` (`U+3099`), without it `ef be 80 ef be 9e 0a` (`U+FF9E`).

To uninstall, delete the two files and restart fcitx5. To disable it, untick *Halfwidth Dakuten* in fcitx5-configtool → *Addons*.

## Limitations

- Only committed text changes; the preedit and the candidates still show `ﾞ`, because fcitx5-lua has no hook for them.
- The kana and its mark must arrive in the same commit. With Mozc they always do.
- Searching for `ﾀﾞﾝﾎﾞｰﾙ` won't find `ﾀ゙ﾝﾎ゙ｰﾙ` unless the search normalizes: NFKC turns both into `ダンボール`.
- Some editors draw combining kana marks poorly ([sakura-editor#1938](https://github.com/sakura-editor/sakura/issues/1938)). In terminals, `U+3099` has zero width, so `ﾀ゙` takes one cell where `ﾀﾞ` took two.

## Development

```sh
lua tests/test.lua halfwidthdakuten.lua
```
