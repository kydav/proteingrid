# App Store screenshots

`make.py` turns six raw simulator screenshots into captioned marketing images
(6.9" 1320×2868, 6.5" 1284×2778 and 6.1"/6.3" 1206×2622), following docs/ASO.md.

1. Run a debug build on a 6.9" simulator. Settings → Debug → Fill a sample year + Pretend Pro.
2. Save these as `raw0.png`…`raw5.png` next to the script:
   - 0: Block Meter, goal hit
   - 1: log sheet open
   - 2: History with THE GRID
   - 3: home-screen long-press menu
   - 4: Arcade Cabinet
   - 5: Neon Vector
3. Download `PressStart2P.ttf` and `VT323.ttf` (Google Fonts) next to it.
4. Run `python3 make.py` (needs Pillow). Output lands in `out/6.9`, `out/6.5` and `out/6.3`.

iPad: put the six iPad 13" shots in `ipad/raw0-5.png` (0 Neon Vector, 1 Arcade, 2 home menu, 3 Block Meter goal hit, 4 log sheet, 5 History) and run `python3 make_ipad.py` → `out/ipad` (2064×2752). `banners.py` makes the App Store header (3840×1646) and search image (1920×1280).

Raw shots, fonts and output are gitignored.
