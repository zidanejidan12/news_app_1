import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:hive/hive.dart';

part 'home.g.dart';

class NewsDetailScreen extends StatelessWidget {
  final News news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(news.title),
      ),
      body: WebView(
        initialUrl: news.url,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}

class WebViewScreen extends StatelessWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Detail'),
      ),
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key})
      : super(key: key); // Added the named 'key' parameter

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<News> favoriteNewsList = [];
  List<News> newsList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchNews().then((news) {
      setState(() {
        newsList = news;
      });
    });
    Hive.openBox<News>('favoriteNews').then((box) {
      setState(() {
        favoriteNewsList = box.values.toList();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    Hive.close();
    super.dispose();
  }

  Future<List<News>> fetchNews() async {
    final response = await http.get(Uri.parse(
        'https://newsapi.org/v2/everything?q=keyword&apiKey=4b397c0b925c48649a61b00c6ab69622'));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      List<News> newsList = [];
      var favoriteNewsBox = Hive.box<News>('favoriteNews');
      for (var item in jsonResponse['articles']) {
        var news = News(
          imageUrl: item['urlToImage'] ?? 'default_image_url',
          title: item['title'] ?? 'default_title',
          description: item['description'] ?? 'default_description',
          url: item['url'] ?? 'default_url', // Added the URL field
        );
        news.isFavorite = favoriteNewsBox.values
            .any((favoriteNews) => favoriteNews.title == news.title);
        newsList.add(news);
        if (newsList.length == 10) {
          break;
        }
      }
      return newsList;
    } else {
      throw Exception('Failed to load news');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News BSI'), // Added the 'const' keyword
        centerTitle: true, // Center the title
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            // Added the 'const' keyword
            Tab(text: 'Home'),
            Tab(text: 'Favorite'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeTab(),
          _buildFavoriteTab(),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 5), // Added the 'const' keyword
      itemCount: newsList.length,
      separatorBuilder: (context, index) =>
          const Divider(), // Added the 'const' keyword
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.all(15), // Added the 'const' keyword
          child: Column(
            children: [
              const SizedBox(
                  height:
                      8), // Add some space (8 pixels), Added the 'const' keyword
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      newsList[index].imageUrl,
                      width: 250,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        newsList[index].isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        setState(() {
                          newsList[index].isFavorite =
                              !newsList[index].isFavorite;
                          var box = Hive.box<News>('favoriteNews');
                          if (newsList[index].isFavorite) {
                            box.add(newsList[index]);
                          } else {
                            box.deleteAt(box.values.toList().indexWhere(
                                (news) => news.title == newsList[index].title));
                          }
                          favoriteNewsList = box.values.toList();
                        });
                      },
                    ),
                  ),
                ],
              ),
              Center(
                child: ListTile(
                  title: Text(
                    newsList[index].title,
                    style: const TextStyle(
                        fontWeight:
                            FontWeight.bold), // Added the 'const' keyword
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFavoriteTab() {
    return ListView.builder(
      itemCount: favoriteNewsList.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    WebViewScreen(url: favoriteNewsList[index].url),
              ),
            );
          },
          child: Card(
            child: ListTile(
              title: Text(
                favoriteNewsList[index].title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold), // Added the 'const' keyword
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}

@HiveType(typeId: 0)
class News {
  @HiveField(0)
  final String imageUrl;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  bool isFavorite;
  @HiveField(4)
  final String url; // Add this line

  News({
    required this.imageUrl,
    required this.title,
    required this.description,
    this.isFavorite = false,
    required this.url, // And this line
  });
}
