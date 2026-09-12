# Agent Instructions

- When any change is made to the app, increment the minor version in `Info.plist` by one (for example, `1.0` to `1.1`).
- Treat the root `Info.plist` as the source of truth; `build-app.sh` copies it into `CoffeeTime.app`.
- Rebuild the app with `./build-app.sh` after changing the version so the bundled metadata stays in sync.