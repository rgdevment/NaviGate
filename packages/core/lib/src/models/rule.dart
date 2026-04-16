import 'package:json_annotation/json_annotation.dart';

part 'rule.g.dart';

@JsonSerializable()
final class Rule {
  const Rule({required this.domain, required this.browserId});

  factory Rule.fromJson(Map<String, dynamic> json) => _$RuleFromJson(json);

  final String domain;
  final String browserId;

  Map<String, dynamic> toJson() => _$RuleToJson(this);

  Rule copyWith({String? domain, String? browserId}) => Rule(
    domain: domain ?? this.domain,
    browserId: browserId ?? this.browserId,
  );
}
