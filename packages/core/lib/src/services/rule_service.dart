import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import '../models/rule.dart';

final class RuleService {
  RuleService({required this.rulesFile});

  final File rulesFile;
  final _log = Logger('RuleService');

  List<Rule> _rules = [];

  List<Rule> get rules => List.unmodifiable(_rules);

  Future<void> load() async {
    if (!rulesFile.existsSync()) {
      _rules = [];
      return;
    }
    _log.info('Loading rules from ${rulesFile.path}');
    final content = await rulesFile.readAsString();
    final decoded = jsonDecode(content) as List;
    _rules = decoded
        .map((e) => Rule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save() async {
    _log.info('Saving ${_rules.length} rules to ${rulesFile.path}');
    await rulesFile.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await rulesFile.writeAsString(
      encoder.convert(_rules.map((r) => r.toJson()).toList()),
    );
  }

  void addRule(Rule rule) {
    _rules = [..._rules.where((r) => r.domain != rule.domain), rule];
  }

  void removeRule(String domain) {
    _rules = _rules.where((r) => r.domain != domain).toList();
  }

  void updateRule(String domain, {required String browserId}) {
    _rules = [
      for (final r in _rules)
        if (r.domain == domain) r.copyWith(browserId: browserId) else r,
    ];
  }

  String? lookupBrowser(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return null;
    return _lookupHierarchical(uri.host);
  }

  String? _lookupHierarchical(String host) {
    final exact = _rules.where((r) => r.domain == host).firstOrNull;
    if (exact != null) return exact.browserId;

    final dotIndex = host.indexOf('.');
    if (dotIndex < 0 || dotIndex == host.length - 1) return null;

    return _lookupHierarchical(host.substring(dotIndex + 1));
  }
}
