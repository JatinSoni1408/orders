# Windows Desktop Build

The Windows package is the admin build of the app. Use Android and iOS builds for user accounts that only need to view and print saved orders.

Use the release package for normal desktop use:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\package_windows_release.ps1
```

That creates a portable folder at `dist\windows\orders`.

Important:

- Copy the whole `dist\windows\orders` folder to another Windows PC or laptop.
- Do not copy only `orders.exe`; the DLLs and `data` folder are required.
- The app needs internet access to sign in and sync with Firestore.
- QR scanning is not available on Windows in the current build.

For convenience on a target machine, create a shortcut to `orders.exe` and place that shortcut on the desktop.
