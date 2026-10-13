# Brand assets

In the Telybot Horizon identity (the website's `docs/BRAND.md`): blush paper
`#efe6eb`, plum ink `#392232`, one copper accent `#a26849`, Archivo Black for
the headline, Lora italic for the note, the robot mark.

| File | Used for |
|---|---|
| `telybot-mark.svg` | the root README; copy of the website's `src/assets/logo/telybot-mark.svg` |
| `social-preview.html` → `social-preview.png` (1280×640) | GitHub → Settings → Social preview |
| `wordpress-banner.html` → `../.wordpress-org/banner-1544x500.png`, `banner-772x250.png` | the WordPress.org listing (SVN `assets/`) |
| `../.wordpress-org/icon-256x256.png`, `icon-128x128.png` | the same, from the website's `telybot-mark.png` |

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
sips -z 256 256 path/to/telybot-mark.png --out .wordpress-org/icon-256x256.png
sips -z 128 128 path/to/telybot-mark.png --out .wordpress-org/icon-128x128.png
```
