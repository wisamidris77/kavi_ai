import 'package:json_annotation/json_annotation.dart';

import '../../providers/base/provider_type.dart';
import 'chat_message_model.dart';

part 'chat_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatModel {
	const ChatModel({
		required this.id,
		required this.title,
		required this.providerType,
		this.model,
		this.messages = const <ChatMessageModel>[],
		this.metadata,
	});

	final String id;
	final String title;
	final AiProviderType providerType;
	final String? model;
	@JsonKey(defaultValue: <ChatMessageModel>[])
	final List<ChatMessageModel> messages;
	final Map<String, dynamic>? metadata;

	factory ChatModel.fromJson(Map<String, dynamic> json) => _$ChatModelFromJson(json);
	Map<String, dynamic> toJson() => _$ChatModelToJson(this);
} 