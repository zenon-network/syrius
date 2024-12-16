part of 'api.dart';

const int _hive = HKEY_CURRENT_USER;

/// An Windows implementation of [ProtocolHandler] that helps creating a custom
/// URL scheme which can open the app through deep linking
///
/// The wallet can be opened through a link like `syrius://...`. It's currently
/// used by the bridge (`https://bridge.mainnet.zenon.community/`) to open the
/// app and send an WalletConnect URI
class WindowsProtocolHandler extends ProtocolHandler {
  @override
  void register(String scheme, {String? executable, List<String>? arguments}) {
    if (defaultTargetPlatform != TargetPlatform.windows) return;

    final String prefix = _regPrefix(scheme);
    final String capitalized = scheme[0].toUpperCase() + scheme.substring(1);
    final Iterable<String> args = getArguments(arguments).map(
      _sanitize,
    );
    final String cmd =
        '${executable ?? Platform.resolvedExecutable} ${args.join(' ')}';

    _regCreateStringKey(_hive, prefix, '', 'URL:$capitalized');
    _regCreateStringKey(_hive, prefix, 'URL Protocol', '');
    _regCreateStringKey(_hive, '$prefix\\shell\\open\\command', '', cmd);
  }

  @override
  void unregister(String scheme) {
    if (defaultTargetPlatform != TargetPlatform.windows) return;

    final LPWSTR txtKey = TEXT(_regPrefix(scheme));
    try {
      RegDeleteTree(HKEY_CURRENT_USER, txtKey);
    } finally {
      free(txtKey);
    }
  }

  String _regPrefix(String scheme) => 'SOFTWARE\\Classes\\$scheme';

  int _regCreateStringKey(int hKey, String key, String valueName, String data) {
    final LPWSTR txtKey = TEXT(key);
    final LPWSTR txtValue = TEXT(valueName);
    final LPWSTR txtData = TEXT(data);
    try {
      return RegSetKeyValue(
        hKey,
        txtKey,
        txtValue,
        REG_VALUE_TYPE.REG_SZ,
        txtData,
        txtData.length * 2 + 2,
      );
    } finally {
      free(txtKey);
      free(txtValue);
      free(txtData);
    }
  }

  String _sanitize(String value) {
    final String finalValue = value.replaceAll('%s', '%1').replaceAll(
          '"',
          r'\"',
        );
    return '"$finalValue"';
  }
}
