# bitmap font notes

## creating font files

- [BitFontMaker2](https://www.pentacom.jp/pentacom/bitfontmaker2/) can import and export ttf files.
  - `menageriall.ttf` is the latest & includes all supported characters. always keep this on hand & iterate if characters need to be changed.
- bitmap fonts consist of a .png and a .fnt (info) file, documented here: https://www.angelcode.com/products/bmfont/doc/file_format.html
- various softwares can convert ttf to BMFont format. the AngelCode generator is the original, but only runs on windows. [FontBuilder](https://github.com/andryblack/fontbuilder) works on linux.
- kerning can be added to ttf files and then preserved when converting to bitmap.
  - FontForge apparently can edit kerning, but crashes on the work laptop. is installed & usable on the x250

## importing & files

- godot font file parser source: https://github.com/godotengine/godot/blob/master/scene/resources/font.cpp
- load a bitmap font to a font file with `load`
- bitmap fonts are "on the way out": https://github.com/godotengine/godot-docs/issues/4743#issuecomment-796982974
- the font file we used in godot 3 was `menagerie.font`. not sure what kind of file this actually is but in godot 4 it can't find the glyphs for any characters so it renders only boxes :(
- `_scratch/font_test.tscn` has a dictionary of kerning pairs we applied manually back in godot 2.1. that version of the file is in git history or in the `menagerie2.1` repo on the x250.

## kerning issues

- godot 4 does not parse kerning data from .fnt files (see kerning section in the angelcode file format doc, looks like `kerning first=123 second=255 amount=1`). it does read the kerning definitions (will error if first or second is >255), but they don't seem to affect the loaded result.
- setting kerning via `font.set_kerning` does work, but only for bitmap fonts, not ttf.
  - the args are: `(0, font_size, chars, Vector2(value, 0))`
    - chars: `Vector2i(a.unicode_at(0), b.unicode_at(0))`
    - cache index is always 0
    - font size comes from `font.fixed_size` (or something like that), which comes from the `size` property in the `info` line in the .fnt file
  - negative values shrink the space between the chars, positive expand. this seems to be backwards from godot 2.1
  - two strategies: configure font with space between characters and selectively shrink that space, or configure font with no space and add it via kerning. both are bugged
    - setting postive kerning adds an extra pixel of space between chars. this only happens for the first kerned pair in a sequence of kerned pairs - eg, if `(p, o)` and `(o, p)` both have kerning 1, then `pop` and `opo` will both have 2 extra pixels between the first 2 letters and 1 extra pixel between the last 2 letters.
    - setting negative kerning shifts the second character in the pair left by the kerning amount but does not move the rest of the characters on the line, creating extra space between the 2nd character and following characters.

summary:

- kerning ttfs doesn't work in godot anymore
- kerning bitmap fonts in godot technically works but is too buggy to be useful

in light of this, it seems like the best solution would be to edit the .ttf output from BitFontMaker in FontForge and add kerning there, then import it without mesing with it further.

# misc

below are all the chars in BitFontMaker. this includes some chars after 255. godot's .fnt parser will complain about these unless the encoding is set to unicode with `unicode=1` on the info line.

```
ABCDEFGHIJKLM
NOPQRSTUVQXYZ
abcdefghijklm
nopqrstuvwxyz
0123456789!"#
$%&'()*+,-./:
;<=>?@[\]^_`{
|}~¡¢£€¤¥¦§¨©

ª«¬®¯°±²³´µ¶·
¸¹º»¼½¾¿ÀÁÂÃÄ
ÅÆÇÈÉÊËÌÍÎÏÐÑ
ÒÓÔÕÖ×ØÙÚÛÜÝÞ
ßàáâãäåæçèéêë
ìíîïðñòóôõö÷ø
ùúûüýþÿĀāĂăĄą
ĆćĈĉĊċČčĎďĐđĒ

ēĔĕĖėĘęĚěĜĝĞğ
ĠġĢģĤĥĦħĨĩĪīĬ
ĭĮįİıĲĳĴĵĶķĸĹ
ĺĻļĽľĿŀŁłŃńŅņ
ŇňŉŊŋŌōŎŏŐőŒœ
ŔŕŖŗŘřŚśŜŝŞşŠ
šŢţŤťŦŧŨũŪūŬŭ
ŮůŰűŲųŴŵŶŷŸŹź
ŻżŽž
```

charset with only <255 chars (includes a bunch of ascii control codes we can put icons like hearts on if needed):

```
	

 !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ€
```

non-unicode chars that would be nice to include (some old bitmap font pngs on the x250 (menagerie2.1 folder) have drawings for some of these):

```
☀★☆♠♡♢♣♤♥♦♧♩♪♫♬
```

(also zodiac signs maybe)