import 'package:json_annotation/json_annotation.dart';
import 'package:kavi/core/chat/chat_message.dart';

import '../../providers/base/provider_type.dart';

class ChatModel {
	const ChatModel({
		required this.id,
		required this.title,
		required this.providerType,
		this.model,
		this.messages = const <ChatMessage>[],
		this.metadata,
	});

	final String id;
	final String title;
	final AiProviderType providerType;
	final String? model;
	final List<ChatMessage> messages;
	final Map<String, dynamic>? metadata;

	factory ChatModel.fromJson(Map<String, dynamic> json) {
		return ChatModel(
			id: json['id'],
			title: json['title'],
			providerType: AiProviderType.values.byName(json['providerType']),
			model: json['model'],
			messages: json['messages'].map((e) => ChatMessage.fromJson(e)).toList(),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'id': id,
			'title': title,
			'providerType': providerType.name,
			'model': model,
			'messages': messages.map((e) => e.toJson()).toList(),
		};
	}
} 