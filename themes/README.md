# Themes

Each theme is a single `colors.toml`. The palettes here are taken from
[Omarchy](https://github.com/omacom/omarchy), which is MIT licensed — see
`LICENSE-omarchy` beside this file.

Only the color data was copied. Omarchy's theme *backgrounds* were not: those
are images with their own provenance, and are not covered by simply carrying
the repository's license.

## The key set

Every palette defines these, so templates can use them without a fallback:

```
mode                                  "dark" or "light"
accent  selection  muted
background  dark_background  darker_background  lighter_background
foreground  dark_foreground  light_foreground  bright_foreground
red  yellow  green  cyan  blue  magenta
bright_red  bright_yellow  bright_green  bright_cyan  bright_blue  bright_magenta
```

`orange` and `brown` are defined by most but not all palettes — use them only
with a fallback. Omarchy's own templates also reference aliases like `purple`
and `selection_foreground`, which their renderer derives; the templates here
avoid those and use the universal keys directly instead.
