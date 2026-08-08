import 'package:flutter/material.dart';
import 'package:telvo/widgets/custom_text_field.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _suggestions = [
    {
      'icon': Icons.calculate,
      'title': 'Estimate your cost',
      'color': Color(0xFF00C853),
    },
    {
      'icon': Icons.photo_camera,
      'title': 'Diagnose from photo',
      'color': Color(0xFF2196F3),
    },
    {
      'icon': Icons.search,
      'title': 'Find best professionals',
      'color': Color(0xFFFF9800),
    },
    {
      'icon': Icons.summarize,
      'title': 'Summarize chat',
      'color': Color(0xFF9C27B0),
    },
    {
      'icon': Icons.translate,
      'title': 'Translate message',
      'color': Color(0xFFE91E63),
    },
  ];

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add({
      'text': 'Hello! How can I help you today?',
      'isUser': false,
      'time': DateTime.now(),
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI Assistant'), elevation: 0),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageBubble(
                message['text'],
                message['isUser'],
                message['time'],
              );
            },
          ),
        ),
        _buildSuggestions(),
        _buildMessageInput(),
      ],
    ),
  );

  Widget _buildMessageBubble(String text, bool isUser, DateTime time) => Align(
    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF00C853) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(color: isUser ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 10,
              color: isUser ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSuggestions() => Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Suggestions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions.map((suggestion) {
            return GestureDetector(
              onTap: () {
                _sendMessage(suggestion['title']);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (suggestion['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (suggestion['color'] as Color).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      suggestion['icon'],
                      color: suggestion['color'],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      suggestion['title'],
                      style: TextStyle(
                        fontSize: 12,
                        color: suggestion['color'],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  Widget _buildMessageInput() => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey.shade200)),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: () {
            // Attach image for diagnosis
          },
          icon: const Icon(Icons.photo_camera, color: Colors.grey),
        ),
        Expanded(
          child: CustomTextField(
            controller: _messageController,
            hintText: 'Ask me anything...',
            onChanged: (value) {
              // Typing indicator
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            if (_messageController.text.trim().isNotEmpty) {
              _sendMessage(_messageController.text);
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF00C853),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ],
    ),
  );

  void _sendMessage(String text) {
    setState(() {
      _messages.add({'text': text, 'isUser': true, 'time': DateTime.now()});
      _messageController.clear();
    });

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add({
          'text': _getAIResponse(text),
          'isUser': false,
          'time': DateTime.now(),
        });
      });
    });
  }

  String _getAIResponse(String query) {
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('cost') || lowerQuery.contains('price')) {
      return 'Based on average rates in your area, the estimated cost is XAF 15,000 - 25,000. Would you like me to find professionals for you?';
    } else if (lowerQuery.contains('plumb') || lowerQuery.contains('pipe')) {
      return 'I can help you find the best plumbers in your area. Do you have a specific plumbing issue?';
    } else if (lowerQuery.contains('electric') ||
        lowerQuery.contains('wiring')) {
      return 'For electrical services, I recommend verified electricians with 5+ years of experience. Would you like me to suggest some?';
    } else if (lowerQuery.contains('clean') || lowerQuery.contains('house')) {
      return 'I can help you find professional cleaners. What type of cleaning do you need?';
    } else if (lowerQuery.contains('photo') || lowerQuery.contains('image')) {
      return 'Please upload a photo of the issue and I\'ll help diagnose it. You can use the camera icon above.';
    } else {
      return 'I understand you\'re looking for help with "$query". Could you provide more details so I can better assist you?';
    }
  }
}
