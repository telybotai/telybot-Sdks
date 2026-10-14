# Brand assets

In the Telybot Horizon identity (the website's `docs/BRAND.md`): blush paper
`#efe6eb`, plum ink `#392232`, one copper accent `#a26849`, Archivo Black for
the headline, Lora italic for the note, the robot logo.

The logo comes in two sets, copied from the website's `src/assets/logo/`:
light mode takes `telybot_light_logo/` (light robot on a plum disc), dark
mode takes `telybot_dark_logo/` (plum robot on a blush disc).

| File | Used for |
|---|---|
| `telybot-logo-light.png`, `telybot-logo-dark.png` | the root README (a `<picture>`, so GitHub shows the one for the reader's theme), and the light one on the cards below; the website's `256.256.png` of each set |
| `social-preview.html` → `social-preview.png` (1280×640) | GitHub → Settings → Social preview |
| `wordpress-banner.html` → `../.wordpress-org/banner-1544x500.png`, `banner-772x250.png` | the WordPress.org listing (SVN `assets/`) |
| `../.wordpress-org/icon-256x256.png`, `icon-128x128.png` | the same; the website's `telybot_light_logo/256.256.png` and `128.128.png` as they are |

The banner's headline is the website's home-page `<h1>`; change them together.
There is no `screenshot-1.png` yet: it needs the settings page from a real
WordPress install, and `readme.txt` gains `== Screenshots ==` in the same commit.

To re-render, from the repository root (the fonts come from Google Fonts, so
give Chrome time to fetch them):

```sh
C="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
R="--headless --hide-scrollbars --virtual-time-budget=9000 --default-background-color=FFFFFFFF"
"$C" $R --window-size=1280,640 --screenshot="$PWD/assets/social-preview.png" "file://$PWD/assets/social-preview.html"
"$C" $R --window-size=1544,500 --screenshot="$PWD/.wordpress-org/banner-1544x500.png" "file://$PWD/assets/wordpress-banner.html"
"$C" $R --window-size=772,250  --screenshot="$PWD/.wordpress-org/banner-772x250.png"  "file://$PWD/assets/wordpress-banner.html"
L=path/to/TelyBot/src/assets/logo
cp $L/telybot_light_logo/256.256.png assets/telybot-logo-light.png
cp $L/telybot_dark_logo/256.256.png  assets/telybot-logo-dark.png
cp $L/telybot_light_logo/256.256.png .wordpress-org/icon-256x256.png
cp $L/telybot_light_logo/128.128.png .wordpress-org/icon-128x128.png
```
