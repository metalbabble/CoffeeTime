# CoffeeTime

CoffeeTime is a small native macOS app that temporarily prevents automatic system sleep while it is running.

- The switch starts **on**.
- Turning it off immediately releases the system sleep assertion.
- Quitting the app releases the assertion as well.
- It changes no macOS power settings and installs no background service.
- The assertion works on both battery and AC power.

## Build

Requires macOS 13 or later and the Swift command-line tools.

```sh
./build-app.sh
open CoffeeTime.app
```

The generated `CoffeeTime.app` can be double-clicked from Finder. This local build is unsigned, so macOS may ask you to confirm opening it the first time.
