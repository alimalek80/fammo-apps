import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../widgets/paw_loading_indicator.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/chat_service.dart';
import '../services/language_service.dart';
import '../models/chat_models.dart';
import '../utils/app_localizations.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _focusNode = FocusNode();

  ChatSession? _currentSession;
  List<ChatMessage> _messages = [];
  List<ChatSession> _sessions = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingSessions = false;
  bool _showScrollToBottom = false;

  // Image preview before sending
  String? _pendingImageData;
  Uint8List? _pendingImageBytes;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadActiveSession();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isNearBottom =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100;
      if (_showScrollToBottom == isNearBottom) {
        setState(() => _showScrollToBottom = !isNearBottom);
      }
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  Future<void> _loadActiveSession() async {
    setState(() => _isLoading = true);

    try {
      final session = await _chatService.getActiveSession();
      setState(() {
        _currentSession = session;
        _messages = session?.messages ?? [];
        _isLoading = false;
      });

      // Scroll to bottom after messages load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animate: false);
      });
    } catch (e) {
      print('Error loading active session: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoadingSessions = true);

    try {
      final sessions = await _chatService.listSessions();
      setState(() {
        _sessions = sessions;
        _isLoadingSessions = false;
      });
    } catch (e) {
      print('Error loading sessions: $e');
      setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _loadSession(int sessionId) async {
    setState(() => _isLoading = true);

    try {
      final session = await _chatService.getSession(sessionId);
      if (session != null) {
        setState(() {
          _currentSession = session;
          _messages = session.messages;
          _isLoading = false;
        });

        Navigator.pop(context); // Close drawer

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(animate: false);
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading session: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createNewSession() async {
    setState(() => _isLoading = true);

    try {
      final session = await _chatService.createNewSession();
      if (session != null) {
        setState(() {
          _currentSession = session;
          _messages = [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error creating session: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    final imageData = _pendingImageData;

    if (message.isEmpty && imageData == null) return;
    if (_isSending) return;

    setState(() {
      _isSending = true;
      _messageController.clear();
      _pendingImageData = null;
      _pendingImageBytes = null;

      // Add temporary user message
      _messages.add(
        ChatMessage.createUserMessage(
          content: message.isNotEmpty ? message : null,
          imageData: imageData,
        ),
      );

      // Add loading message for AI
      _messages.add(ChatMessage.createLoadingMessage());
    });

    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(
        message: message.isNotEmpty ? message : null,
        imageData: imageData,
        sessionId: _currentSession?.id,
      );

      if (response != null) {
        setState(() {
          // Remove temporary messages
          _messages.removeWhere((m) => m.id < 0);

          // Add real messages
          _messages.add(response.userMessage);
          _messages.add(response.assistantMessage);

          // Update session ID if new session was created
          if (_currentSession == null ||
              _currentSession!.id != response.sessionId) {
            _currentSession = ChatSession(
              id: response.sessionId,
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
        });

        _scrollToBottom();
      } else {
        // Remove loading message on error
        setState(() {
          _messages.removeWhere((m) => m.id < 0);
        });

        _showErrorSnackBar('Failed to send message. Please try again.');
      }
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        _messages.removeWhere((m) => m.id < 0);
      });

      _showErrorSnackBar('Network error. Please check your connection.');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _sendMessage,
          ),
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final mimeType = _getMimeType(image.path);
        final base64String = base64Encode(bytes);

        setState(() {
          _pendingImageData = '$mimeType;base64,$base64String';
          _pendingImageBytes = bytes;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image');
    }
  }

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26B5A4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF26B5A4)),
                ),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26B5A4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF26B5A4),
                  ),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearPendingImage() {
    setState(() {
      _pendingImageData = null;
      _pendingImageBytes = null;
    });
  }

  Future<void> _deleteSession(int sessionId) async {
    final success = await _chatService.deleteSession(sessionId);
    if (success) {
      setState(() {
        _sessions.removeWhere((s) => s.id == sessionId);
        if (_currentSession?.id == sessionId) {
          _currentSession = null;
          _messages = [];
        }
      });
    }
  }

  void _showFullScreenImage(String imageData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageView(imageData: imageData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: LanguageService().getLocalLanguage(),
      builder: (context, snapshot) {
        String languageCode = snapshot.data ?? 'en';
        AppLocalizations loc = AppLocalizations(languageCode);

        return Scaffold(
          backgroundColor: const Color(0xFFFFF8F0),
          appBar: AppBar(
            backgroundColor: const Color(0xFF26B5A4),
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  _loadSessions();
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            title: Text(
              loc.chat,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _createNewSession,
                tooltip: 'New Chat',
              ),
            ],
          ),
          drawer: _buildChatHistoryDrawer(loc),
          body: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: PawLoadingIndicator())
                    : _messages.isEmpty
                    ? _buildEmptyState(loc)
                    : _buildMessageList(),
              ),
              _buildInputArea(loc),
            ],
          ),
          floatingActionButton: _showScrollToBottom
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: FloatingActionButton.small(
                    onPressed: () => _scrollToBottom(),
                    backgroundColor: const Color(0xFF26B5A4),
                    child: const Icon(
                      Icons.arrow_downward,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
          bottomNavigationBar: const BottomNavBar(activePage: 'Chat'),
        );
      },
    );
  }

  Widget _buildChatHistoryDrawer(AppLocalizations loc) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFF26B5A4)),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    loc.translate('chatHistory'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // New Chat Button
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createNewSession,
                  icon: const Icon(Icons.add),
                  label: Text(loc.translate('newChat')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26B5A4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // Sessions List
            Expanded(
              child: _isLoadingSessions
                  ? const Center(child: PawLoadingIndicator())
                  : _sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            loc.translate('noChatHistory'),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSessions,
                      child: ListView.builder(
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          final isActive = _currentSession?.id == session.id;

                          return Dismissible(
                            key: Key('session_${session.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => _deleteSession(session.id),
                            child: ListTile(
                              selected: isActive,
                              selectedTileColor: const Color(
                                0xFF26B5A4,
                              ).withOpacity(0.1),
                              leading: Icon(
                                Icons.chat_bubble_outline,
                                color: isActive
                                    ? const Color(0xFF26B5A4)
                                    : Colors.grey.shade600,
                              ),
                              title: Text(
                                session.title ?? loc.translate('untitledChat'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                _formatSessionDate(session.updatedAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              onTap: () => _loadSession(session.id),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSessionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.EEEE().format(date);
    } else {
      return DateFormat.MMMd().format(date);
    }
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF26B5A4).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets, size: 64, color: Color(0xFF26B5A4)),
            ),
            const SizedBox(height: 24),
            Text(
              loc.translate('welcomeToChat'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.translate('chatWelcomeMessage'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Ask about pet nutrition', loc),
                _buildSuggestionChip('Get health advice', loc),
                _buildSuggestionChip('Upload a pet photo', loc),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, AppLocalizations loc) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _messageController.text = text;
        _focusNode.requestFocus();
      },
      backgroundColor: Colors.white,
      side: BorderSide(color: const Color(0xFF26B5A4).withOpacity(0.3)),
      labelStyle: const TextStyle(color: Color(0xFF26B5A4)),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isLoading = message.id < 0 && message.isAssistant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF26B5A4),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.pets, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF26B5A4) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isLoading
                  ? _buildTypingIndicator()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.hasImage) ...[
                          _buildMessageImage(message, isUser),
                          if (message.content != null &&
                              message.content!.isNotEmpty)
                            const SizedBox(height: 8),
                        ],
                        if (message.content != null &&
                            message.content!.isNotEmpty)
                          isUser
                              ? Text(
                                  message.content!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                )
                              : MarkdownBody(
                                  data: message.content!,
                                  selectable: true,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(
                                      color: Color(0xFF2C3E50),
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                    strong: const TextStyle(
                                      color: Color(0xFF2C3E50),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    em: const TextStyle(
                                      color: Color(0xFF2C3E50),
                                      fontSize: 15,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    listBullet: const TextStyle(
                                      color: Color(0xFF2C3E50),
                                      fontSize: 15,
                                    ),
                                    h1: const TextStyle(
                                      color: Color(0xFF2C3E50),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h2: const TextStyle(
                                      color: Color(0xFF2C3E50),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h3: const TextStyle(
                                      color: Color(0xFF2C3E50),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    code: TextStyle(
                                      color: const Color(0xFF2C3E50),
                                      backgroundColor: Colors.grey.shade200,
                                      fontSize: 14,
                                    ),
                                    codeblockDecoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                      ],
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5C01D),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 200)),
          builder: (context, value, child) {
            return Container(
              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF26B5A4,
                  ).withOpacity(0.3 + (value * 0.7)),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildMessageImage(ChatMessage message, bool isUser) {
    // Check if we have a URL from the server
    if (message.imageUrl != null && message.imageUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: () => _showFullScreenImage(message.imageUrl!),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.imageUrl!,
            fit: BoxFit.cover,
            width: 200,
            height: 150,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF26B5A4)),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      );
    }

    // Handle base64 image data (for locally added images before sending)
    if (message.imageData != null && message.imageData!.isNotEmpty) {
      Uint8List? imageBytes;
      try {
        final imageData = message.imageData!;
        final parts = imageData.split(';base64,');
        if (parts.length == 2) {
          imageBytes = base64Decode(parts[1]);
        }
      } catch (e) {
        print('Error decoding image: $e');
      }

      if (imageBytes != null) {
        return GestureDetector(
          onTap: () => _showFullScreenImage(message.imageData!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              width: 200,
              height: 150,
            ),
          ),
        );
      }
    }

    // Fallback for broken images
    return Container(
      height: 150,
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }

  Widget _buildInputArea(AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview
            if (_pendingImageBytes != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _pendingImageBytes!,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        onPressed: _clearPendingImage,
                      ),
                    ),
                  ],
                ),
              ),

            // Input row
            Row(
              children: [
                // Image picker button
                IconButton(
                  onPressed: _isSending ? null : _showImagePickerOptions,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  color: const Color(0xFF26B5A4),
                ),

                // Text input
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      enabled: !_isSending,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: loc.translate('typeMessage'),
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF26B5A4),
                              ),
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    color: const Color(0xFF26B5A4),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF26B5A4).withOpacity(0.1),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full screen image viewer
class _FullScreenImageView extends StatelessWidget {
  final String imageData;

  const _FullScreenImageView({required this.imageData});

  bool get _isUrl =>
      imageData.startsWith('http://') || imageData.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(child: _isUrl ? _buildNetworkImage() : _buildBase64Image()),
    );
  }

  Widget _buildNetworkImage() {
    return InteractiveViewer(
      child: Image.network(
        imageData,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const CircularProgressIndicator(color: Colors.white);
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, color: Colors.white, size: 64);
        },
      ),
    );
  }

  Widget _buildBase64Image() {
    Uint8List? imageBytes;
    try {
      final parts = imageData.split(';base64,');
      if (parts.length == 2) {
        imageBytes = base64Decode(parts[1]);
      }
    } catch (e) {
      print('Error decoding image: $e');
    }

    if (imageBytes != null) {
      return InteractiveViewer(child: Image.memory(imageBytes));
    }
    return const Icon(Icons.broken_image, color: Colors.white, size: 64);
  }
}
