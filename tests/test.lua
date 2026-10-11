-- Runs halfwidthdakuten.lua outside fcitx5 with a stub `fcitx` module.
--   lua tests/test.lua halfwidthdakuten.lua
local script = assert(arg[1], "usage: lua tests/test.lua halfwidthdakuten.lua")

local converter
package.loaded.fcitx = { addConverter = function(fn) converter = fn end }
dofile(script)
local function commit(s) return _G[converter](s) end

local failures, count = 0, 0
local function hex(s)
    local t = {}
    for _, cp in utf8.codes(s) do
        t[#t + 1] = string.format("U+%04X", cp)
    end
    return table.concat(t, " ")
end
local function check(name, got, want)
    count = count + 1
    if got ~= want then
        failures = failures + 1
        print(("FAIL %s\n  got  %s (%s)\n  want %s (%s)"):format(
            name, got, hex(got), want, hex(want)))
    end
end

check("voiced", commit("ﾀﾞﾝﾎﾞｰﾙ"), "ﾀ\u{3099}ﾝﾎ\u{3099}ｰﾙ")
check("semivoiced", commit("ﾊﾟﾝ"), "ﾊ\u{309A}ﾝ")
check("vu", commit("ｳﾞ"), "ｳ\u{3099}")
check("first letter ｦ", commit("ｦﾞ"), "ｦ\u{3099}")
check("last letter ﾝ", commit("ﾝﾟ"), "ﾝ\u{309A}")
check("lone mark", commit("ﾞ"), "ﾞ")
check("second mark stays", commit("ﾀﾞﾞ"), "ﾀ\u{3099}ﾞ")
check("after kanji", commit("国ﾞ"), "国ﾞ")
check("after fullwidth kana", commit("ダﾞ"), "ダﾞ")
check("after ascii", commit("aﾟ"), "aﾟ")
check("combining untouched", commit("ﾀ\u{3099}"), "ﾀ\u{3099}")
check("no marks", commit("ちょっと国abc"), "ちょっと国abc")
check("empty", commit(""), "")

print(("%d/%d passed"):format(count - failures, count))
os.exit(failures == 0 and 0 or 1)
