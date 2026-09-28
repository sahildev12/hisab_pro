# HisabPro — Web Deploy

## Upload zip to https://hisabpro.dise.org.in/

1. Build (already done when `hisabpro-web-deploy.zip` exists):
   ```bash
   flutter build web --release --base-href /
   ```
2. Upload **`hisabpro-web-deploy.zip`** from the project root.
3. Extract **all files** into the website root (public_html / www) so `index.html` sits at the domain root.
4. After extract you must see these folders next to `index.html`:
   - `assets/` (contains `fonts/MaterialIcons-Regular.otf`)
   - `canvaskit/`
   - `icons/`
5. Test in browser: open `https://your-domain/assets/FontManifest.json` — it must **not** be 404.
6. If icons show as crossed boxes, the `assets/fonts/` folder was not uploaded or `.htaccess` MIME types are missing.

## Rebuild zip (Windows PowerShell)

```powershell
flutter build web --release --base-href /
Compress-Archive -Path build\web\* -DestinationPath hisabpro-web-deploy.zip -Force
```

## Web shell app (separate project)

For a native app that only opens the website, use the sibling folder:

`C:\xampp\htdocs\hisab_pro_web_shell`

This does **not** modify the main `hisab_pro` app.
