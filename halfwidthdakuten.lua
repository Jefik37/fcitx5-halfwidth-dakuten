-- Rewrites committed text so that halfwidth katakana use the combining
-- (semi-)voiced sound marks instead of the spacing halfwidth ones:
--
--   ﾀﾞﾝﾎﾞｰﾙ (U+FF80 U+FF9E ...)  ->  ﾀ゙ﾝﾎ゙ｰﾙ (U+FF80 U+3099 ...)
--
-- U+FF9E/U+FF9F are, per Unicode, the <narrow> compatibility forms of
-- U+3099/U+309A; this just undoes that substitution.
local fcitx = require("fcitx")

-- ﾞ/ﾟ (halfwidth, spacing) -> ゙/゚ (combining)
local MARKS = { [0xFF9E] = 0x3099, [0xFF9F] = 0x309A }

-- Halfwidth katakana letters that can carry a mark: ｦ (U+FF66) .. ﾝ (U+FF9D).
local function is_halfwidth_kana(cp)
    return cp ~= nil and cp >= 0xFF66 and cp <= 0xFF9D
end

-- Must be a global: fcitx.addConverter() looks the function up by name.
function halfwidth_dakuten_to_combining(str)
    -- Fast path: U+FF9E/U+FF9F are EF BE 9E / EF BE 9F in UTF-8.
    if not str:find("\xEF\xBE[\x9E\x9F]") then
        return str
    end
    local out, prev = {}, nil
    for _, cp in utf8.codes(str) do
        -- A mark with no kana before it (e.g. typed on its own) stays spacing,
        -- otherwise it would combine with whatever character precedes it.
        if MARKS[cp] and is_halfwidth_kana(prev) then
            out[#out + 1] = utf8.char(MARKS[cp])
        else
            out[#out + 1] = utf8.char(cp)
        end
        prev = cp
    end
    return table.concat(out)
end

fcitx.addConverter("halfwidth_dakuten_to_combining")
