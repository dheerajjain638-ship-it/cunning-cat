import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/live_api.dart';
import '../data/live_models.dart';

final liveApiProvider = Provider<LiveApi>((ref) => LiveApi());

/// Live search results. Kept for the session so going back never re-bills a search.
final liveSearchProvider = FutureProvider.family<List<LiveProduct>, String>(
  (ref, query) => ref.watch(liveApiProvider).search(query),
);

final liveDetailProvider = FutureProvider.family<LiveDetail, String>(
  (ref, token) => ref.watch(liveApiProvider).product(token),
);

final aiInsightProvider = FutureProvider.family<AiInsight, String>(
  (ref, token) => ref.watch(liveApiProvider).insights(token),
);

class ChatMessage {
  final bool fromUser;
  final String text;
  final AskAnswer? answer;
  final bool isError;
  const ChatMessage.user(this.text)
      : fromUser = true,
        answer = null,
        isError = false;
  const ChatMessage.cat(this.text, {this.answer, this.isError = false}) : fromUser = false;
}

class AskState {
  final List<ChatMessage> messages;
  final bool busy;
  const AskState(this.messages, {this.busy = false});
}

class AskNotifier extends Notifier<AskState> {
  @override
  AskState build() => const AskState([]);

  Future<void> send(String text) async {
    final message = text.trim();
    if (message.isEmpty || state.busy) return;
    final history = [
      for (final m in state.messages)
        if (!m.isError) (role: m.fromUser ? 'user' : 'assistant', text: m.text),
    ];
    state = AskState([...state.messages, ChatMessage.user(message)], busy: true);
    try {
      final answer = await ref.read(liveApiProvider).ask(message, history);
      state = AskState([...state.messages, ChatMessage.cat(answer.reply, answer: answer)]);
    } catch (e) {
      state = AskState([...state.messages, ChatMessage.cat('$e', isError: true)]);
    }
  }

  void reset() => state = const AskState([]);
}

final askProvider = NotifierProvider<AskNotifier, AskState>(AskNotifier.new);
