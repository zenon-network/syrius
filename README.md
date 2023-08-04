# s y r i u s

[![Build and release syrius](https://github.com/hypercore-one/syrius/actions/workflows/syrius_builder.yml/badge.svg?branch=develop)](https://github.com/hypercore-one/syrius/actions/workflows/syrius_builder.yml) [![Library updater for syrius](https://github.com/hypercore-one/syrius/actions/workflows/syrius_lib_updater.yml/badge.svg?branch=develop)](https://github.com/hypercore-one/syrius/actions/workflows/syrius_lib_updater.yml)

Cross-platform non-custodial wallet designed for Alphanet - Network of Momentum Phase 0.

Developed in Flutter using the [Zenon Dart SDK](https://github.com/zenon-network/znn_sdk_dart), `s y r i u s` wallet provides a simple and intuitive interface to interact with Network of Momentum Phase 0.

## Architecture

The wallet has a modular design with native full node integration. There are three operation modes of the wallet depending on user preference:

- [Embedded Node](https://github.com/zenon-network/go-zenon) mode: integrated full node
- Local Node mode: connect to your own full node
- Remote Node: connect to a third party node

## Building

Follow the instructions to install the [Flutter SDK](https://docs.flutter.dev/get-started/install). Check the [documentation](https://docs.flutter.dev/desktop) in order to setup the Flutter desktop environment.

Learn about the foreign function interface (ffi) [here](https://docs.flutter.dev/development/platform-integration/c-interop) that enables state-of-the art KDF - [Argon2](https://github.com/zenon-network/argon2_ffi), feeless transactions - [PoW links](https://github.com/zenon-network/znn-pow-links-cpp) and native full node integration - [Embedded Node](https://github.com/zenon-network/go-zenon).

Dependencies:

- Flutter: `>=2.10.x`
- Dart: `>=2.16.x`

Currently supported `<os>`: `windows`, `macos`, `linux`

The [WalletConnect](https://github.com/WalletConnect) integration requires setting the `WC_PROJECT_ID` environmental variable.

```bash
git clone https://github.com/zenon-network/syrius.git
flutter pub get
flutter run --dart-define=WC_PROJECT_ID=walletconnect_project_id -d <os>
flutter build --dart-define=WC_PROJECT_ID=walletconnect_project_id <os>
```

## Contributing

Please check [CONTRIBUTING](./CONTRIBUTING.md) for more details.

## License

The MIT License (MIT). Please check [LICENSE](./LICENSE) for more information.
