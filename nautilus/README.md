# Nautilus

Nautilus scripts for image-content clipboard interoperability with DMS and
Wayland applications:

- **Copy image contents** copies one selected image as `image/png` through the
  native DMS clipboard CLI. Non-PNG images are converted with ImageMagick so
  Chrome and Google Docs receive a compatible clipboard offer.
- **Paste clipboard image** reads the current Wayland image offer and creates
  a PNG in the open local folder. This complements the installed DMS CLI's
  text-only `clipboard paste` command.

These are explicit actions under Nautilus's **Scripts** submenu. Ordinary
`Ctrl+C` and `Ctrl+V` remain unchanged, so Nautilus-to-Nautilus file copies
continue to preserve file names, formats, and metadata.
