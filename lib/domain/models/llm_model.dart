import 'package:json_annotation/json_annotation.dart';

import '../../providers/base/provider_type.dart';

part 'llm_model.g.dart';

@JsonSerializable()
class LlmModel {
	const LlmModel({
		required this.name,
		required this.providerType,
		this.contextWindow,
		this.supportsTools = false,
		this.capabilities,
	});

	final String name;
	final AiProviderType providerType;
	final int? contextWindow;
	@JsonKey(defaultValue: false)
	final bool supportsTools;
	final Map<String, dynamic>? capabilities;

	factory LlmModel.fromJson(Map<String, dynamic> json) => _$LlmModelFromJson(json);
	Map<String, dynamic> toJson() => _$LlmModelToJson(this);
} 