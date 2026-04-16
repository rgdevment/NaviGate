import 'browser.dart';

final class BrowserConfig {
  const BrowserConfig({this.schemaVersion = '1.0', this.browsers = const []});

  factory BrowserConfig.fromJson(Map<String, dynamic> json) => BrowserConfig(
    schemaVersion: json['schema_version'] as String? ?? '1.0',
    browsers:
        (json['browsers'] as List?)
            ?.map((e) => Browser.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  final String schemaVersion;
  final List<Browser> browsers;

  Map<String, dynamic> toJson() => {
    'schema_version': schemaVersion,
    'browsers': browsers.map((b) => b.toJson()).toList(),
  };
}
