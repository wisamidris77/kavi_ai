import 'package:json_annotation/json_annotation.dart';

import 'chat_role.dart';

part 'chat_message_model.g.dart';

@JsonSerializable()
class ChatMessageModel {
	const ChatMessageModel({
		required this.id,
		required this.role,
		required this.content,
		this.chatId,
		this.toolCallIds = const <String>[],
		this.createdAt,
		this.metadata,
	});

	final String id;
	final ChatRole role;
	final String content;
	@JsonKey(defaultValue: <String>[])
	final List<String> toolCallIds;
  final String? chatId; 
	final DateTime? createdAt;
	final Map<String, dynamic>? metadata;

	factory ChatMessageModel.fromJson(Map<String, dynamic> json) => _$ChatMessageModelFromJson(json);
	Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);

	factory ChatMessageModel.system(String content) => ChatMessageModel(
		id: _genId(),
		role: ChatRole.system,
		content: content,
		createdAt: DateTime.now(),
	);

	factory ChatMessageModel.user(String content) => ChatMessageModel(
		id: _genId(),
		role: ChatRole.user,
		content: content,
		createdAt: DateTime.now(),
	);

	factory ChatMessageModel.assistant(String content) => ChatMessageModel(
		id: _genId(),
		role: ChatRole.assistant,
		content: content,
		createdAt: DateTime.now(),
	);
}

String _genId() => DateTime.now().microsecondsSinceEpoch.toString(); 