import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:duoob_desktop_app_v1/view/components/modern_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const _kDirectLineBaseUrl =
    'https://europe.directline.botframework.com/v3/directline';

const _thinkingIndicatorText = 'Thinking';

int _parseExpiresIn(Map<String, dynamic> json) {
  final val = json['expires_in'] ?? json['expiresIn'];
  if (val is int) return val;
  if (val is String) return int.tryParse(val) ?? 3600;
  return 3600;
}

class BackendDirectLineToken {
  const BackendDirectLineToken({
    required this.token,
    required this.expiresIn,
    required this.userId,
  });

  final String token;
  final int expiresIn;
  final String userId;

  factory BackendDirectLineToken.fromJson(Map<String, dynamic> json) {
    return BackendDirectLineToken(
      token: json['token'] as String,
      expiresIn: _parseExpiresIn(json),
      userId: (json['userId'] as String?) ??
          'user_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}

class BackendRefreshedDirectLineToken {
  const BackendRefreshedDirectLineToken({
    required this.token,
    required this.expiresIn,
  });

  final String token;
  final int expiresIn;

  factory BackendRefreshedDirectLineToken.fromJson(Map<String, dynamic> json) {
    return BackendRefreshedDirectLineToken(
      token: json['token'] as String,
      expiresIn: _parseExpiresIn(json),
    );
  }
}

class DirectLineConversation {
  const DirectLineConversation({
    required this.conversationId,
    required this.token,
    required this.streamUrl,
    required this.expiresIn,
  });

  final String conversationId;
  final String token;
  final String streamUrl;
  final int expiresIn;

  factory DirectLineConversation.fromJson(Map<String, dynamic> json) {
    return DirectLineConversation(
      conversationId: json['conversationId'] as String,
      token: json['token'] as String,
      streamUrl: json['streamUrl'] as String,
      expiresIn: _parseExpiresIn(json),
    );
  }
}

enum ChatAuthor { user, bot, system }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.author,
    required this.createdAt,
  });

  final String id;
  final String text;
  final ChatAuthor author;
  final DateTime createdAt;
}

class CopilotBackendApi {
  CopilotBackendApi({
    required this.baseUrl,
    required this.appAccessToken,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final String appAccessToken;
  final http.Client _httpClient;

  Future<BackendDirectLineToken> fetchToken({String locale = 'en-US'}) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/api/copilot/session'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'locale': locale}),
    );

    log(response.body);

    log(response.body, name: 'CopilotBackendApi');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to fetch Direct Line token. '
        'Status=${response.statusCode}, Body=${response.body}',
      );
    }

    return BackendDirectLineToken.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<BackendRefreshedDirectLineToken> refreshToken(
    String currentToken,
  ) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/api/copilot/refresh'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'token': currentToken}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to refresh Direct Line token. '
        'Status=${response.statusCode}, Body=${response.body}',
      );
    }

    return BackendRefreshedDirectLineToken.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  void dispose() {
    _httpClient.close();
  }
}

class DirectLineClient {
  DirectLineClient({
    required Future<BackendRefreshedDirectLineToken> Function(
      String currentToken,
    )
        onRefreshToken,
    required this.locale,
    this.appAccessToken,
    http.Client? httpClient,
    this.directLineBaseUrl = _kDirectLineBaseUrl,
  })  : _onRefreshToken = onRefreshToken,
        _httpClient = httpClient ?? http.Client();

  final Future<BackendRefreshedDirectLineToken> Function(String currentToken)
      _onRefreshToken;
  final String locale;
  final String? appAccessToken;
  final String directLineBaseUrl;
  final http.Client _httpClient;

  final StreamController<ChatMessage> _messagesController =
      StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get messages => _messagesController.stream;

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _refreshTimer;
  Timer? _reconnectTimer;

  late String _userId;
  late String _currentToken;
  late String _conversationId;
  late String _streamUrl;
  String? _watermark;
  bool _started = false;
  bool _reconnecting = false;
  bool _disposed = false;
  final Set<String> _seenActivityIds = <String>{};

  static const _legacyUserId = 'dl_test_user';
  /// Direct Line user id expected by the production Copilot / backend mapping.
  static const _directLineUserId = _legacyUserId;

  bool _isLocalUser(String? fromId) {
    if (fromId == null || fromId.isEmpty) return false;
    return fromId == _userId ||
        fromId == _directLineUserId ||
        fromId == _legacyUserId;
  }

  Future<void> start(BackendDirectLineToken backendToken) async {
    _userId = backendToken.userId;
    _currentToken = backendToken.token;

    final conversation = await _startConversation();
    _conversationId = conversation.conversationId;
    _currentToken = conversation.token;
    _streamUrl = conversation.streamUrl;

    _scheduleTokenRefresh(conversation.expiresIn);
    _connectSocket();

    try {
      await _sendEvent('startConversation');
    } catch (e) {
      debugPrint('Warning: Bot rejected startConversation event: $e');
    }

    _started = true;
  }

  Future<void> sendMessage(String text) async {
    if (!_started) {
      throw StateError('Direct Line client is not started.');
    }

    await ensureConnected();

    await _postActivityWithRecovery({
      'type': 'message',
      'text': text,
      'textFormat': 'plain',
      'locale': locale,
      'from': {
        'id': _directLineUserId,
        'name': 'IT Account',
      },
    });
  }

  Future<void> ensureConnected() async {
    if (!_started || _disposed) return;
    if (_channel == null) {
      await _reconnectSocket(refreshTokenFirst: true);
    }
  }

  Future<void> ensureSessionAlive() async {
    if (!_started || _disposed) return;
    await _reconnectSocket(refreshTokenFirst: true);
  }

  Future<void> dispose() async {
    _disposed = true;
    _refreshTimer?.cancel();
    _reconnectTimer?.cancel();
    await _disconnectSocket();
    await _messagesController.close();
    _httpClient.close();
  }

  Future<DirectLineConversation> _startConversation() async {
    final response = await _httpClient.post(
      Uri.parse('$directLineBaseUrl/conversations'),
      headers: {
        'Authorization': 'Bearer $_currentToken',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to start Direct Line conversation. '
        'Status=${response.statusCode}, Body=${response.body}',
      );
    }

    return DirectLineConversation.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> _sendEvent(String name) async {
    await _postActivity({
      'type': 'event',
      'name': name,
      'from': {
        'id': _userId,
        'name': _userId,
      },
      'locale': locale,
    });
  }

  Future<void> _postActivityWithRecovery(Map<String, dynamic> activity) async {
    try {
      await _postActivity(activity);
    } catch (e) {
      debugPrint('Direct Line post failed, recovering session: $e');
      await _reconnectSocket(refreshTokenFirst: true);
      await _postActivity(activity);
    }
  }

  Future<void> _postActivity(Map<String, dynamic> activity) async {
    final response = await _httpClient.post(
      Uri.parse(
        '$directLineBaseUrl/conversations/$_conversationId/activities',
      ),
      headers: {
        'Authorization': 'Bearer $_currentToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(activity),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to post Direct Line activity. '
        'Status=${response.statusCode}, Body=${response.body}',
      );
    }
  }

  Future<void> _disconnectSocket() async {
    await _channelSubscription?.cancel();
    _channelSubscription = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _updateStreamUrlToken() {
    final uri = Uri.parse(_streamUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    params['t'] = _currentToken;
    if (_watermark != null && _watermark!.isNotEmpty) {
      params['watermark'] = _watermark!;
    }
    _streamUrl = uri.replace(queryParameters: params).toString();
  }

  void _connectSocket() {
    _channel = WebSocketChannel.connect(Uri.parse(_streamUrl));
    _channelSubscription = _channel!.stream.listen(
      _handleSocketPayload,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Direct Line socket error: $error');
        _channel = null;
        _channelSubscription = null;
        _scheduleReconnect();
      },
      onDone: () {
        debugPrint('Direct Line socket closed.');
        _channel = null;
        _channelSubscription = null;
        if (_started && !_disposed) {
          _scheduleReconnect();
        }
      },
      cancelOnError: false,
    );
  }

  void _scheduleReconnect() {
    if (_disposed || !_started || _reconnecting) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 1), () {
      unawaited(_reconnectSocket(refreshTokenFirst: true));
    });
  }

  Future<void> _reconnectSocket({required bool refreshTokenFirst}) async {
    if (_disposed || !_started || _reconnecting) return;

    _reconnecting = true;
    try {
      if (refreshTokenFirst) {
        final refreshed = await _onRefreshToken(_currentToken);
        _currentToken = refreshed.token;
        _scheduleTokenRefresh(refreshed.expiresIn);
      }
      _updateStreamUrlToken();
      await _disconnectSocket();
      _connectSocket();
    } catch (error, stackTrace) {
      debugPrint('Direct Line reconnect failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _reconnecting = false;
    }
  }

  void _handleSocketPayload(dynamic raw) {
    final rawStr = raw as String?;
    if (rawStr == null || rawStr.trim().isEmpty) return;

    final payload = jsonDecode(rawStr) as Map<String, dynamic>;
    final watermark = payload['watermark'];
    if (watermark != null) {
      _watermark = watermark.toString();
    }
    final activities = (payload['activities'] as List?) ?? const [];

    for (final item in activities) {
      final activity = item as Map<String, dynamic>;
      final activityId = activity['id'] as String?;
      if (activityId != null) {
        if (_seenActivityIds.contains(activityId)) continue;
        _seenActivityIds.add(activityId);
      }

      if (activity['attachments'] != null &&
          appAccessToken != null &&
          appAccessToken!.isNotEmpty) {
        final attachments = activity['attachments'] as List;

        for (var attachment in attachments) {
          if (attachment['contentType'] ==
              'application/vnd.microsoft.card.oauth') {
            final content = attachment['content'] as Map<String, dynamic>?;
            final connectionName = content?['connectionName'] as String?;
            final tokenExchangeResource =
                content?['tokenExchangeResource'] as Map<String, dynamic>?;
            final id = tokenExchangeResource?['id'] as String? ??
                content?['id'] as String? ??
                '';

            if (connectionName != null) {
              unawaited(_postActivity({
                'type': 'invoke',
                'name': 'signin/tokenExchange',
                'value': {
                  'id': id,
                  'connectionName': connectionName,
                  'token': appAccessToken,
                },
                'from': {
                  'id': _directLineUserId,
                  'name': 'IT Account',
                },
              }));
              return;
            }
          }
        }
      }

      final type = activity['type'] as String?;

      if (type == 'typing') {
        _messagesController.add(
          ChatMessage(
            id: activity['id'] as String? ?? _newId(),
            text: _thinkingIndicatorText,
            author: ChatAuthor.system,
            createdAt: DateTime.now(),
          ),
        );
        continue;
      }

      if (type != 'message') {
        continue;
      }

      final from = activity['from'] as Map<String, dynamic>? ?? const {};
      final fromId = from['id'] as String?;

      // Skip echoes of messages we already show optimistically in the UI.
      if (_isLocalUser(fromId)) {
        continue;
      }

      String? text = activity['text'] as String?;

      if (text == null || text.trim().isEmpty) {
        if (activity['attachments'] != null) {
          final attachments = activity['attachments'] as List;
          for (var attachment in attachments) {
            final content = attachment['content'];
            if (content is Map<String, dynamic>) {
              if (content.containsKey('text')) {
                text = content['text'] as String?;
                break;
              } else if (content.containsKey('body')) {
                final body = content['body'] as List?;
                if (body != null && body.isNotEmpty) {
                  final firstItem = body.first;
                  if (firstItem is Map && firstItem.containsKey('text')) {
                    text = firstItem['text'] as String?;
                    break;
                  }
                }
              }
            }
          }
        }
      }

      if (text == null || text.trim().isEmpty) {
        continue;
      }

      _messagesController.add(
        ChatMessage(
          id: activity['id'] as String? ?? _newId(),
          text: text,
          author: ChatAuthor.bot,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  void _scheduleTokenRefresh(int expiresInSeconds) {
    _refreshTimer?.cancel();

    final refreshAfter = Duration(
      seconds: expiresInSeconds > 120
          ? expiresInSeconds - 120
          : expiresInSeconds ~/ 2,
    );

    _refreshTimer = Timer(refreshAfter, () async {
      try {
        final refreshed = await _onRefreshToken(_currentToken);
        _currentToken = refreshed.token;
        _updateStreamUrlToken();
        await _reconnectSocket(refreshTokenFirst: false);
        _scheduleTokenRefresh(refreshed.expiresIn);
      } catch (error, stackTrace) {
        debugPrint('Direct Line token refresh failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}

class CopilotChatController extends ChangeNotifier {
  CopilotChatController({
    required this.backendApi,
    this.locale = 'en-US',
  });

  final CopilotBackendApi backendApi;
  final String locale;

  final List<ChatMessage> _messages = <ChatMessage>[];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  DirectLineClient? _directLineClient;

  bool _isInitializing = false;
  bool get isInitializing => _isInitializing;

  bool _isSending = false;
  bool get isSending => _isSending;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_isInitializing || _directLineClient != null) {
      return;
    }

    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final backendToken = await backendApi.fetchToken(locale: locale);

      final client = DirectLineClient(
        locale: locale,
        appAccessToken: backendApi.appAccessToken,
        onRefreshToken: backendApi.refreshToken,
      );

      await client.start(backendToken);

      client.messages.listen((ChatMessage message) {
        if (message.author == ChatAuthor.system &&
            message.text == _thinkingIndicatorText) {
          if (_messages.isNotEmpty &&
              _messages.last.author == ChatAuthor.system) {
            return;
          }
        } else if (message.author == ChatAuthor.bot) {
          _messages.removeWhere((m) =>
              m.author == ChatAuthor.system &&
              m.text == _thinkingIndicatorText);

          final lastUserIndex =
              _messages.lastIndexWhere((m) => m.author == ChatAuthor.user);
          if (lastUserIndex != -1 &&
              _messages[lastUserIndex].text.trim() == message.text.trim()) {
            return;
          }
        }

        _messages.add(message);
        notifyListeners();
      });

      _directLineClient = client;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> ensureSessionAlive() async {
    await _directLineClient?.ensureSessionAlive();
  }

  Future<void> reinitialize() async {
    await _directLineClient?.dispose();
    _directLineClient = null;
    _isInitializing = false;
    await initialize();
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _directLineClient == null || _isSending) {
      return;
    }

    _messages.add(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: trimmed,
        author: ChatAuthor.user,
        createdAt: DateTime.now(),
      ),
    );
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _directLineClient!.ensureConnected();
      await _directLineClient!.sendMessage(trimmed);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> close() async {
    await _directLineClient?.dispose();
    backendApi.dispose();
  }
}

class CopilotChatPage extends StatefulWidget {
  const CopilotChatPage({
    super.key,
    required this.backendBaseUrl,
    required this.appAccessToken,
    this.locale = 'en-US',
    this.title = 'Ask RAKP AI',
    this.embedded = false,
  });

  final String backendBaseUrl;
  final String appAccessToken;
  final String locale;
  final String title;
  final bool embedded;

  @override
  State<CopilotChatPage> createState() => _CopilotChatPageState();
}

class _CopilotChatPageState extends State<CopilotChatPage>
    with WidgetsBindingObserver {
  late final CopilotChatController _controller;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  Timer? _keepAliveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = CopilotChatController(
      backendApi: CopilotBackendApi(
        baseUrl: widget.backendBaseUrl,
        appAccessToken: widget.appAccessToken,
      ),
      locale: widget.locale,
    );
    unawaited(_controller.initialize());
    _controller.addListener(_scrollToBottomSoon);
    _keepAliveTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(_controller.ensureSessionAlive()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.ensureSessionAlive());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keepAliveTimer?.cancel();
    _controller.removeListener(_scrollToBottomSoon);
    unawaited(_controller.close());
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final chatBody = _buildChatBody(context);

        if (widget.embedded) {
          return chatBody;
        }

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: AppColors.blue,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: chatBody,
          ),
        );
      },
    );
  }

  Widget _buildChatBody(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          if (_controller.errorMessage != null)
            MaterialBanner(
              content: Text(_controller.errorMessage!),
              actions: [
                TextButton(
                  onPressed: _controller.isInitializing
                      ? null
                      : () => unawaited(_controller.reinitialize()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          Expanded(
            child: _controller.isInitializing
                ? const Center(child: ModernLoadingIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = _controller.messages[index];
                      return _ChatBubble(
                        message: message,
                        onUseInInput: _useMessageInInput,
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _inputFocusNode,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      style: const TextStyle(color: Colors.black),
                      cursorColor: AppColors.black,
                      decoration: InputDecoration(
                        hintText: 'Ask Copilot something...',
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.black,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      shape: const CircleBorder(),
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: _controller.isInitializing || _controller.isSending
                        ? null
                        : _handleSend,
                    icon: _controller.isSending
                        ? const ModernLoadingIndicator(
                            color: Colors.white,
                            compact: true,
                            dotSize: 6,
                            spacing: 4,
                          )
                        : const Icon(
                            Icons.send_outlined,
                            color: Colors.white,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _useMessageInInput(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _textController.text = trimmed;
    _textController.selection = TextSelection.collapsed(offset: trimmed.length);
    _inputFocusNode.requestFocus();
  }

  void _handleSend() {
    final text = _textController.text;
    _textController.clear();
    FocusScope.of(context).unfocus();
    unawaited(_controller.sendMessage(text));
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 72,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.onUseInInput,
  });

  final ChatMessage message;
  final void Function(String text) onUseInInput;

  Future<void> _copyText(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: message.text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.author == ChatAuthor.user;
    final bool isSystem = message.author == ChatAuthor.system;

    if (isSystem) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ModernLoadingIndicator(
              label: _thinkingIndicatorText,
              color: AppColors.blue.withValues(alpha: 0.85),
            ),
          ),
        ),
      );
    }

    final Color bubbleColor = isUser
        ? AppColors.blue
        : Colors.grey.shade200;

    final Color textColor = isUser ? Colors.white : Colors.black87;
    final Color actionColor =
        isUser ? Colors.white.withValues(alpha: 0.92) : AppColors.blue;
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.55;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxBubbleWidth.clamp(280, 720),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 6),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectionArea(
              child: MarkdownBody(
                data: message.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: textColor, fontSize: 16),
                  a: TextStyle(
                    color: isUser ? Colors.white : Colors.blue.shade700,
                    decoration: TextDecoration.underline,
                  ),
                ),
                onTapLink: (text, href, title) async {
                  if (href != null) {
                    final uri = Uri.parse(href);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Divider(
              height: 1,
              color: actionColor.withValues(alpha: 0.22),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _BubbleIconAction(
                  tooltip: 'Copy',
                  icon: Icons.content_copy_outlined,
                  color: actionColor,
                  onPressed: () => _copyText(context),
                ),
                _BubbleIconAction(
                  tooltip: 'Use in input',
                  icon: Icons.reply_outlined,
                  color: actionColor,
                  onPressed: () => onUseInInput(message.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleIconAction extends StatelessWidget {
  const _BubbleIconAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        color: color,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        splashRadius: 18,
      ),
    );
  }
}
