--[[
MIT LICENSE
Copyright © 2024 John Riggles [sudo_whoami]

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local sluggify = { }

-- local utf8 = require("utf8") -- utf8 lib is required to handle special characters
-- NOTE: utf8 library is included in Aseprite as a global

local letters = { -- mapping of replacement characters
    ["áàâǎăãảȧạäåḁāąⱥȁấầẫẩậắằẵẳặǻǡǟȁȃａ"] = "a",
    ["ÁÀÂǍĂÃẢȦẠÄÅḀĀĄȺȀẤẦẪẨẬẮẰẴẲẶǺǠǞȀȂＡ"] = "A",
    ["ḃḅḇƀᵬᶀｂ"] = "b",
    ["ḂḄḆɃƁʙＢ"] = "B",
    ["ćĉčċçḉȼɕｃƇ"] = "c",
    ["ĆĈČĊÇḈȻＣƈ"] = "C",
    ["ďḋḑḍḓḏđɗƌｄᵭᶁᶑȡ"] = "d",
    ["ĎḊḐḌḒḎĐƉƊƋＤᴅᶑȡ"] = "D",
    ["éèêḙěĕẽḛẻėëēȩęɇȅếềễểḝḗḕȇẹệｅᶒⱸ"] = "e",
    ["ÉÈÊḘĚĔẼḚẺĖËĒȨĘɆȄẾỀỄỂḜḖḔȆẸỆＥᴇ"] = "E",
    ["ḟƒｆᵮᶂ"] = "f",
    ["ḞƑＦ"] = "F",
    ["ǵğĝǧġģḡǥɠｇᶃ"] = "g",
    ["ǴĞĜǦĠĢḠǤƓＧɢ"] = "G",
    ["ĥȟḧḣḩḥḫ̱ẖħⱨｈ"] = "h",
    ["ĤȞḦḢḨḤḪĦⱧＨʜ"] = "H",
    ["íìĭîǐïḯĩįīỉȉȋịḭɨiıｉ"] = "i",
    ["ÍÌĬÎǏÏḮĨĮĪỈȈȊỊḬƗİIＩ"] = "I",
    ["ĵɉｊʝɟʄǰ"] = "j",
    ["ĴɈＪᴊ"] = "J",
    ["ḱǩķḳḵƙⱪꝁｋᶄ"] = "k",
    ["ḰǨĶḲḴƘⱩꝀＫᴋ"] = "K",
    ["ĺľļḷḹḽḻłŀƚⱡɫｌɬᶅɭȴ"] = "l",
    ["ĹĽĻḶḸḼḺŁĿȽⱠⱢＬʟ"] = "L",
    ["ḿṁṃɱｍᵯᶆ"] = "m",
    ["ḾṀṂⱮＭᴍ"] = "M",
    ["ńǹňñṅņṇṋṉɲƞｎŋᵰᶇɳȵ"] = "n",
    ["ŃǸŇÑṄŅṆṊṈṉƝȠＮŊɴ"] = "N",
    ["óòŏôốồỗổǒöȫőõṍṏȭȯȱøǿǫǭōṓṑỏȍȏơớờỡởợọộɵｏⱺᴏ"] = "o",
    ["ÓÒŎÔỐỒỖỔǑÖȪŐÕṌṎȬȮȰØǾǪǬŌṒṐỎȌȎƠỚỜỠỞỢỌỘƟＯ"] = "O",
    ["ṕṗᵽ"] = "p",
    ["ṔṖⱣƤＰ"] = "P",
    ["ɋʠｑ"] = "q",
    ["ɊＱ"] = "Q",
    ["ŕřṙŗȑȓṛṝṟɍɽｒᵲᶉɼɾᵳ"] = "r",
    ["ŔŘṘŖȐȒṚṜṞɌⱤＲʀ"] = "R",
    ["śṥŝšṧṡşṣṩșｓßẛᵴᶊʂȿſ"] = "s",
    ["ŚṤŜŠṦṠŞṢṨȘＳẞ"] = "S",
    ["ťṫţṭțṱṯŧⱦƭʈｔẗᵵƫȶ"] = "t",
    ["ŤṪŢṬȚṰṮŦȾƬƮＴᴛ"] = "T",
    ["úùŭûǔůüǘǜǚǖűũṹųūṻủȕȗưứừữửựụṳṷṵʉᶙ"] = "u",
    ["ÚÙŬÛǓŮÜǗǛǙǕŰŨṸŲŪṺỦȔȖƯỨỪỮỬỰỤṲṶṴɄＵ"] = "U",
    ["ṽṿʋｖⱱⱴᴠᶌ"] = "v",
    ["ṼṾƲＶ"] = "V",
    ["ẃẁŵẅẇẉⱳｗẘ"] = "w",
    ["ẂẀŴẄẆẈⱲＷ"] = "W",
    ["ẍẋｘᶍ"] = "x",
    ["ẌẊＸ"] = "X",
    ["ýỳŷÿỹẏȳỷỵɏƴｙẙ"] = "y",
    ["ÝỲŶŸỸẎȲỶỴɎƳＹʏ"] = "Y",
    ["źẑžżẓẕƶȥⱬｚᵶᶎʐʑɀᴢ"] = "z",
    ["ŹẐŽŻẒẔƵȤⱫＺ"] = "Z",
}

local function replaceAccents(str)
    local normalizedString = '' -- declare an empty string to store the normalized output
    for _, char in utf8.codes(str) do -- convert the strign into constituent utf8 bytes
        local replaced = false
        for accentChars, replacementChar in pairs(letters) do -- for each set of accented chars and their corresponding replacement...
            for _, accent in utf8.codes(accentChars) do -- get the utf8 code for the given accent char
                if char == accent then -- if the byte value of the current character in the input string matches the byte value of the an accent char
                    normalizedString = normalizedString .. replacementChar -- append its corresponding replacement char to the output string
                    replaced = true
                    break
                end
            end
            if replaced then
                break
            end
        end
        if not replaced then -- no replacementChar necessary, append the character as-is
            normalizedString = normalizedString .. utf8.char(char)
        end
    end
    return normalizedString
end

function sluggify.sluggify(text)
    local slug = text
        :gsub("[\\/ ]+", "-") -- replace slashes and spaces with dashes "-"
        slug = replaceAccents(slug) -- replace all accent characters w/ their 'normal' equiv.
        :gsub("[^A-Za-z0-9%-]+", "") -- remove all non-alphanumeric characters
        :gsub("[%-]+", "-") -- replace multiple consecutive dashes with a single dash
        :gsub("^%-+", "") -- remove leading dashes
        :gsub("%-+$", "") -- remove trailing dashes
        :lower()
    return slug
end

return sluggify
