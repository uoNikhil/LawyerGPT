import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For converting the response body to a JSON format

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LegalGPT',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple, // Primary color for the app
        scaffoldBackgroundColor: Colors.white, // Background color of the app
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple, // AppBar color
          foregroundColor: Colors.white, // AppBar icons and text color
          shape: RoundedRectangleBorder( // Rounded bottom shape
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
        ),
        textTheme: TextTheme(
          bodyText2: TextStyle(color: Colors.deepPurple), // General text color in the app
        ),
      ),
      home: FutureBuilder(
        future: Future.delayed(Duration(seconds: 2)), // Simulate some loading time
        builder: (context, snapshot) {
          // Check if the future is completed
          if (snapshot.connectionState == ConnectionState.done) {
            return const ChatBotScreen(); // Go to main screen after loading
          } else {
            return const SplashScreen(); // Show splash screen while loading
          }
        },
      ),
    );
  }
}

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({Key? key}) : super(key: key);

  @override
  _ChatBotState createState() => _ChatBotState();
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class _ChatBotState extends State<ChatBotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> messages = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
          title: Text(
          "LegatGPT", // Your desired title text
          style: TextStyle(
          color: Colors.white, // Choose a color that fits the app's theme
          fontSize: 20, // Optional: Adjust the font size
          ),
          ),
        backgroundColor: Colors.deepPurple, // AppBar color to match the theme
        leading: InkWell(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Padding(
            padding: EdgeInsets.all(10.0), // Add your desired padding value here
            child: Image.asset("assets/law.png", width: 30, height: 30),
          ),
        ),

      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: Colors.deepPurple),
              title: Text('Home', style: TextStyle(color: Colors.deepPurple)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.login, color: Colors.deepPurple),
              title: Text('Login', style: TextStyle(color: Colors.deepPurple)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.app_registration, color: Colors.deepPurple),
              title: Text('Signup', style: TextStyle(color: Colors.deepPurple)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: Stack(
        children: <Widget>[
          Center(
          child: Transform.scale(
            scale: 0.7,
            child:Opacity(
              opacity: messages.isEmpty ? 0.7 : 0.5, // Full opacity when no messages, half-opacity otherwise
              child: Image.asset(
                'assets/law.png',
                fit: BoxFit.contain,
              ),
           ),
          ),
          ),
          Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return ChatBubble(message: messages[index]);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: "Type your message here...",
                          hintStyle: TextStyle(color: Colors.deepPurple.withOpacity(0.6)),
                          fillColor: Colors.deepPurple.withOpacity(0.2),
                          filled: true,
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    FloatingActionButton(
                      backgroundColor: Colors.deepPurple,
                      onPressed: () {

                        _addMessage(_textController.text, true);
                        if (_textController.text.isNotEmpty) {

                          if (_isBasicGreeting(_textController.text)) {
                            Future.delayed(Duration(seconds: 1), () { // Optional delay to mimic processing time
                              _addMessage("How can I help you with your legal queries?", false);
                            });

                            _textController.clear ();
                        }
                          else
                            {
                              postQuestion(_textController.text);
                            }

                        }
                      },
                      child: Transform.rotate(
                        angle: -0.6, // Adjust the angle to achieve the desired slant. This is in radians.
                        child: Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> postQuestion(String question) async {
    // API URL
    var url = "http://10.0.2.2:5000/query";

    // Your request body
    Map<String, dynamic> requestBody = {
      "question": question,
    };
    print("post request");
    try {
      // Make the POST request
      var response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json", // Specify the content type as JSON
        },
        body: json.encode(requestBody), // Convert requestBody map to a JSON string
      );
      // Check if the request was successful
      if (response.statusCode == 200) {
        // Decode the response body
        var data = json.decode(response.body);

        // Use the response data
        print('Response data: $data');

        var reply = data['response']['response'];
        var path = data['response']['documentPaths'];

        _addMessage(reply, false);
        print(path[0]);

        var mes = 'The source of the document' + path[0];

        _addMessage(mes, false);





      } else {
        // Handle errors
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      // Handle any exceptions
      print('Exception caught: $e');
    }

    _textController.clear ();
  }


  void _addMessage(String message, bool isUser) {
    setState(() {
      messages.add(ChatMessage(text: message, isUser: isUser));

    });
  }

}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.deepPurple : Colors.pink,
          borderRadius: message.isUser
              ? BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          )
              : BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: Border.all(color: Colors.deepPurple),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.white,
            fontSize: 18.0,
          ),
        ),
      ),
    );
  }
}


class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepPurple,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "AI for Legal Advice",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              decoration: TextDecoration.none,
              fontFamily: 'Arial',
            ),
          ),
          SizedBox(height: 20),
          Image.asset('assets/lgbt.png', width: 200), // Your splash image
        ],
      ),
    );
  }
}

bool _isBasicGreeting(String message) {
  // Convert the message to lowercase for case-insensitive comparison
  final String lowerCaseMessage = message.toLowerCase();

  // List of basic greetings
  const List<String> basicGreetings = ["hi", "hello", "hey","Hi", "Hello", "Hey"];

  // Check if the message is in the list of basic greetings
  return basicGreetings.contains(lowerCaseMessage);
}
