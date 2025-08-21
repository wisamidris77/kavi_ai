import 'dart:async';



import '../../domain/domain.dart' as domain;
import '../../providers/providers.dart' as providers;
import 'ai_chat_service.dart';
import 'chat_message.dart';

class ProviderAiChatService implements AiChatService {
	ProviderAiChatService({
		required providers.AiProviderType providerType,
		required providers.AiProviderConfig config,
		String? model,
		this.temperature,
		this.maxTokens,
	})  : _providerType = providerType,
			_model = model,
			_service = domain.AiChatService(providerType: providerType, config: config);

	final providers.AiProviderType _providerType;
	final String? _model;
	final double? temperature;
	final int? maxTokens;

	final domain.AiChatService _service;
	final Map<String, StreamSubscription<String>> _inflight = {};
	final Map<String, StreamController<ChatMessage>> _controllers = {};

	@override
	Stream<ChatMessage> sendMessage({
		required List<ChatMessage> history,
		required String prompt,
	}) {
		final String messageId = 'a_${DateTime.now().microsecondsSinceEpoch}';
		final controller = StreamController<ChatMessage>();
		_controllers[messageId] = controller;

		final domainHistory = history
			.map((m) => ChatMessage(
				id: m.id,
				role: m.role,
				content: m.content,
				createdAt: m.createdAt,
			))
			.toList(growable: false);

		final accumulator = StringBuffer();
		Future<void>.microtask(() {
			final sub = _service
				.streamReply(
					history: domainHistory,
					userInput: prompt,
					model: _model,
					temperature: temperature,
					maxTokens: maxTokens,
				)
				.listen((chunk) {
					accumulator.write(chunk);
					final update = ChatMessage(
						id: messageId,
						role: ChatRole.assistant,
						content: accumulator.toString(),
						createdAt: DateTime.now(),
					);
					if (!controller.isClosed) controller.add(update);
				}, onError: (Object err, StackTrace st) async {
					await controller.close();
					_inflight.remove(messageId);
					_controllers.remove(messageId);
				}, onDone: () async {
					await controller.close();
					_inflight.remove(messageId);
					_controllers.remove(messageId);
				});

			_inflight[messageId] = sub;
		});

		return controller.stream;
	}

	@override
	Future<void> abort({required String messageId}) async {
		await _inflight.remove(messageId)?.cancel();
		await _controllers.remove(messageId)?.close();
	}
} 