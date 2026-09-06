# __e_kaomoji <exit-status>  ->  a mood-appropriate kaomoji
function __e_kaomoji
    set -l st $argv[1]
    test -n "$st"; or set st 0
    if test $st -eq 0
        set -l happy \
            '(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧' '( ˶ˆ ᗜ ˆ˵ )' '(๑˃ᴗ˂)ﻭ' 'ヽ(´▽`)/' '(*ﾉ´∀`*)' \
            'ᕕ( ᐛ )ᕗ' '(っ˘ω˘ς )' '( ᐛ )و' '(◕‿◕)♡' '＼(＾▽＾)／'
        echo $happy[(random 1 (count $happy))]
    else
        set -l sad \
            '(╥﹏╥)' '( ｡•́︿•̀｡ )' '(´；ω；`)' 'ヽ(｀⌒´メ)ノ' '(っ- ‸ - ς)' \
            '(ノಠ益ಠ)ノ彡┻━┻' '( ˘•̥̥̥ω•̥̥̥˘ )' '(눈_눈)' 'ლ(ಠ益ಠ)ლ'
        echo $sad[(random 1 (count $sad))]
    end
end
