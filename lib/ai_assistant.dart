import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SalesPerformancePage extends StatefulWidget {
  const SalesPerformancePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SalesPerformancePageState createState() => _SalesPerformancePageState();
}

class _SalesPerformancePageState extends State<SalesPerformancePage> {
  String _loggedInUsername = '';
  String _salesmanName = '';
  Map<String, dynamic> _performanceData = {};
  List<Map<String, dynamic>> _leadsData = [];
  bool _isLoading = true;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final EdgeInsets _uniformPadding = const EdgeInsets.all(16.0);
  final List<Map<String, dynamic>> _messages = [];
  bool isTyping = false;
  int _interactionStep = 0;
  List<String> _suggestions = [
    "Which leads should I prioritize",
    "How to improve my weakness",
    "How to close deals",
    "Plan my day"
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadChatFromCache();
  }

  Future<void> _loadUsername() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInUsername = prefs.getString('username') ?? '';
    });
    _fetchSalesPerformance();
    _fetchSalesLeads();
  }

  Future<void> _loadChatFromCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? chatHistory = prefs.getString('chat_history');
    if (chatHistory != null) {
      setState(() {
        _messages
            .addAll(List<Map<String, dynamic>>.from(json.decode(chatHistory)));
      });
    } else {
      _sendInitialSalesOverview();
    }
  }

  Future<void> _saveChatToCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history', json.encode(_messages));
  }

  Future<void> _resetChat() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
    setState(() {
      _messages.clear();
      _interactionStep = 0;
      _controller.clear();
      _suggestions = [
        "Which leads should I prioritize",
        "How to improve my weakness",
        "How to close deals",
        "Plan my day"
      ];
    });
    await _saveChatToCache();
    _sendInitialSalesOverview();
  }

  void _fetchSalesPerformance() async {
    final url =
        'https://haluansama.com/crm-sales/api/ai_assistant/get_salesman_performance.php?username=$_loggedInUsername';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] is List) {
          final List<dynamic> dataList = responseData['data'];

          if (dataList.isNotEmpty) {
            setState(() {
              _salesmanName = dataList[0]['salesman_name'] ?? 'Salesman';
              _performanceData = Map<String, dynamic>.from(dataList[0]);
              _isLoading = false;
            });
          }
        } else {
          _showError("Unexpected response format or status.");
        }
      } else {
        _showError(
            "Failed to load performance. Status code: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Network error: $e");
    }
  }

  Widget _buildChatBubble(String message, {String? boldText}) {
    return Container(
      padding: _uniformPadding,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'Inter',
            color: Colors.black,
          ),
          children: [
            TextSpan(text: message),
            if (boldText != null)
              TextSpan(
                text: boldText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Inter',
                  color: Color(0xff0175FF),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchSalesLeads() async {
    final url =
        'https://haluansama.com/crm-sales/api/ai_assistant/get_sales_lead.php?username=$_loggedInUsername';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success' &&
            responseData['data'] is List) {
          List<Map<String, dynamic>> leads = List<Map<String, dynamic>>.from(
            responseData['data'].map((lead) {
              return {
                "lead_id": lead['lead_id'] ?? 0,
                "customer_name": lead['customer_name'] ?? 'N/A',
                "contact_number": lead['contact_number'] ?? 'N/A',
                "predicted_sales": _parseToDouble(lead['predicted_sales']),
                "stage": lead['stage'] ?? 'N/A',
                "negotiation_start_date": lead['negotiation_start_date'] ?? '',
                "task_duedate": lead['task_duedate'] ?? '',
                "task_title": lead['task_title'] ?? 'No Task',
              };
            }),
          );

          setState(() {
            _leadsData = leads;
            _isLoading = false;
          });

          if (_messages.isEmpty) {
            _sendInitialSalesOverview();
          }
        } else {
          _showError("Unexpected response format or status.");
        }
      } else {
        _showError("Failed to load leads. Status code: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Network error: $e");
    }
  }

  void _sendInitialSalesOverview({bool refresh = false}) {
    List<Map<String, dynamic>> stuckNegotiations = _leadsData.where((lead) {
      final status = lead['stage'] ?? '';
      final negotiationStartDate = lead['negotiation_start_date'];

      if (status.toLowerCase() != 'negotiation' ||
          negotiationStartDate.isEmpty) {
        return false;
      }

      DateTime? startDate;
      try {
        startDate = DateTime.parse(negotiationStartDate);
      } catch (e) {
        return false;
      }

      final daysStuck = DateTime.now().difference(startDate).inDays;
      return daysStuck > 7;
    }).toList();

    String initialMessage = "Here's your current sales overview:\n";

    List<Map<String, dynamic>> negotiationLeads = _leadsData.where((lead) {
      return lead['stage']?.toLowerCase() == 'negotiation';
    }).toList();

    Map<String, dynamic>? highValueLead = negotiationLeads.isNotEmpty
        ? negotiationLeads.reduce(
            (a, b) => a['predicted_sales'] > b['predicted_sales'] ? a : b)
        : null;

    if (highValueLead != null) {
      final formattedSales = NumberFormat.currency(
        locale: 'en_MY',
        symbol: 'RM ',
        decimalDigits: 2,
      ).format(highValueLead['predicted_sales']);

      initialMessage +=
          "Highest Predicted Sale in Negotiation: $formattedSales with ${highValueLead['customer_name']}.\n";
    } else {
      initialMessage += "No high-value leads found in the negotiation stage.\n";
    }

    if (stuckNegotiations.isNotEmpty) {
      initialMessage +=
          "You have ${stuckNegotiations.length} negotiations stuck for over 7 days. Want to resolve them?";
    } else {
      initialMessage +=
          "No negotiations have been stuck for over 7 days. Would you like to focus on high-value opportunities?";
    }

    if (refresh) {
      setState(() {
        _messages.removeWhere((msg) => msg['isUser'] == false);
        _messages.add({
          "message": initialMessage,
          "isUser": false,
          "timestamp": _getCurrentTime(),
        });
      });
    } else {
      _addMessageToChat(initialMessage);
    }
  }

  void _addMessageToChat(String message) {
    setState(() {
      _messages.add({
        "message": message,
        "isUser": false,
        "timestamp": _getCurrentTime(),
      });
    });

    _saveChatToCache();
    _scrollToBottom();
  }

  List<TextSpan> _getFormattedTextSpans(String message) {
    final List<TextSpan> spans = [];
    final regex = RegExp(r'\*\*(.*?)\*\*|###(.*?)###|([^*#]+)');
    final matches = regex.allMatches(message);

    for (final match in matches) {
      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: '\n${match.group(2)}\n',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(text: match.group(3)));
      }
    }

    return spans;
  }

  Future<void> _handleSendMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      _messages.add({
        "message": message,
        "isUser": true,
        "timestamp": _getCurrentTime(),
      });
      _controller.clear();
      isTyping = true;
    });

    _saveChatToCache();
    _scrollToBottom();
    await _fetchAISuggestions(message);
    await _saveChatToCache();

    setState(() {
      isTyping = false;
    });

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _fetchAISuggestions(String prompt) async {
    setState(() {
      isTyping = true;
    });

    const openAiUrl = 'https://api.openai.com/v1/chat/completions';
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    String leadDataSummary = _getLeadDataSummary();

    String additionalSystemMessage = "If the user asks about their weaknesses, "
        "Make sure format of the values and total are in this format(RM 5,000.00)"
        "Ensure responses are concise, actionable, and supportive, within 400 tokens or less."
        "analyze the current sales data and identify potential issues such as low number of leads, "
        "long-stuck negotiations, or lack of engagement. Provide actionable tips to improve these areas. "
        "Be supportive, concise, and use relevant data from the database to deliver personalized feedback.";

    final requestBody = json.encode({
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content": "You are a specialized AI Sales Assistant designed to help with sales-related tasks only. "
              "Make sure format of the values and total are in this format(RM 5,000.00)"
              "Ensure responses are concise, actionable, and supportive, within 400 tokens or less."
              "Your main goals are to assist in advancing sales leads, resolving stuck negotiations, prioritizing high-value opportunities, and creating daily sales plans. "
              "Respond specifically to the following requests: "
              "1. **'Which leads should I prioritize'**: Identify the most critical sales task based on the current leads' status, such as high-value leads, stuck negotiations, or upcoming tasks. "
              "2. **'How to improve my weakness' or 'Tell me my weakness'**: Analyze the sales data to highlight areas where the user may be lacking, like fewer leads, prolonged negotiations, or lack of engagement. "
              "3. **'How to close deals'**: Offer clear, actionable strategies for closing deals, such as negotiation tactics, creating urgency, or offering limited-time incentives. "
              "4. **'Plan my day'**: Create a prioritized daily schedule based on the most urgent tasks, high-value leads, or follow-ups required for advancing negotiations. "
              "$additionalSystemMessage"
        },
        {"role": "assistant", "content": "Sales Lead Data: $leadDataSummary"},
        {"role": "user", "content": prompt}
      ],
      "max_tokens": 600,
      "temperature": 0.2
    });

    try {
      final response = await http.post(
        Uri.parse(openAiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final aiMessage = utf8.decode(
            responseData['choices'][0]['message']['content'].runes.toList());

        setState(() {
          _messages.add({
            "message": aiMessage,
            "isUser": false,
            "timestamp": _getCurrentTime(),
          });
          isTyping = false;
        });

        await _saveChatToCache();
        _scrollToBottom();
      } else {
        _showError(
            "Failed to fetch AI response. Status code: ${response.statusCode}");
        setState(() {
          isTyping = false;
        });
      }
    } catch (e) {
      _showError("Error in AI response: $e");
      setState(() {
        isTyping = false;
      });
    }
  }

  String _getLeadDataSummary() {
    if (_leadsData.isEmpty) return "No sales lead data available.";

    return _leadsData.map((lead) {
      return "${lead['customer_name']} (Predicted Sales: RM ${lead['predicted_sales']}, Stage: ${lead['stage']})";
    }).join("; ");
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
  }

  double _parseToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSuggestion(String suggestion) {
    _controller.text = suggestion;
    _handleSendMessage(suggestion);
    setState(() {
      // Suggestions are not removed
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        title: const Text(
          'AI Sales Assistant',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            right: -40,
            child: Image.asset(
              'asset/top_start.png',
              width: 300,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: -40,
            left: 0,
            child: Image.asset(
              'asset/bttm_start.png',
              width: 250,
              height: 250,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: Container(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          Column(
            children: [
              _buildCustomBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildChatBubble(
                              'Welcome back, ',
                              boldText: _salesmanName,
                            ),
                            const SizedBox(height: 5),
                            _buildChatBubble(
                              'Here’s your current sales status:',
                            ),
                            const SizedBox(height: 10),
                            _buildPerformanceWidgets(),
                            const SizedBox(height: 20),
                            _buildChatInterface(),
                          ],
                        ),
                      ),
              ),
              _buildMessageInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: _messages.map((message) {
        final isUser = message["isUser"] as bool;
        final timestamp = message["timestamp"] as String;
        final content = message["message"] as String;

        final List<TextSpan> formattedContent = _getFormattedTextSpans(content);

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            padding: _uniformPadding,
            decoration: BoxDecoration(
              color: isUser ? const Color(0xff0175FF) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: formattedContent,
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Inter',
                      color: isUser ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  timestamp,
                  style: TextStyle(
                    color: isUser ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessageInputArea() {
    return Column(
      children: [
        if (_suggestions.isNotEmpty)
          Padding(
            padding: _uniformPadding,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _suggestions.map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      onPressed: () {
                        _handleSuggestion(suggestion);
                      },
                      child: Text(
                        suggestion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        if (isTyping)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(width: 10),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
                SizedBox(width: 10),
                Text('Sales Navigator Smart Agent is typing...'),
              ],
            ),
          ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xff0175FF)),
                onPressed: () => _handleSendMessage(_controller.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.chat, color: Colors.blue),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sales Lead Smart Bot',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                'Sales Navigator Smart Agent',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _resetChat,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceWidgets() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _buildPerformanceCard(
            "Opportunities",
            _performanceData['leads_opportunities'],
            Colors.blue,
            Icons.analytics),
        _buildPerformanceCard("Engaged", _performanceData['leads_engaged'],
            Colors.orange, Icons.group),
        _buildPerformanceCard(
            "Negotiated",
            _performanceData['leads_negotiated'],
            Colors.green,
            Icons.handshake),
        _buildPerformanceCard("Closed", _performanceData['leads_closed'],
            Colors.purple, Icons.check_circle),
      ],
    );
  }

  Widget _buildPerformanceCard(
      String title, dynamic value, Color color, IconData icon) {
    final displayValue = value != null ? value.toString() : '0';
    return Container(
      padding: _uniformPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 15, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
