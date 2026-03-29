# orders

Flutter order-management app with platform-specific access:

- Windows: admin app for creating, editing, syncing, and printing orders.
- Android and iOS: user app for viewing and printing saved orders.

## Windows build

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\package_windows_release.ps1
```

The packaged desktop app is created in `dist\windows\orders`.
