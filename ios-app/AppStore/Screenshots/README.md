# App Store screenshots

## Upload-ready sets

- `Upload-Ready/iPhone-6.9`: 8 opaque JPEGs, 1320×2868 pixels.
- `Upload-Ready/iPad-13`: 8 opaque JPEGs, 2048×2732 pixels.

Both sizes are accepted by App Store Connect as of 14 July 2026. Upload one to ten images per device family. The recommended order is recorded in `../../APP_STORE_LISTING.md`.

## Capture provenance

- iPhone: iPhone 17 Pro Max simulator, iOS 26.2.
- iPad upload set: iPad Pro 12.9-inch (6th generation) simulator, iPadOS 16.1, captured full screen at an accepted 13-inch App Store size.
- Every image is a native Simulator capture of a real app view.
- Storage was reset before each launch so the images do not expose a child's information.
- Status-bar battery and connectivity were normalised where supported.

## Non-upload folders

- `iPhone-6.9`: raw Simulator PNGs. They contain alpha and are retained only as capture masters.
- `iPad-13-fullscreen`: raw full-screen iPad PNGs. They contain alpha and are retained only as capture masters.
- `iPad-13`: iPadOS 26 resizable-window audit captures. They include the Home Screen and Dock and must not be submitted.

Apple does not accept screenshot files with alpha channels. Use only the JPEGs under `Upload-Ready`.

