import 'package:fetch_api/beer_page.dart';
import 'package:fetch_api/the_beer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme:
        ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 10, 102, 255)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Beer List'),
    );
  }
}

int currentPage = 1;
int perPage = 10;
List<Beer> beers = [];
bool isLoading = false;
final ScrollController _scrollController = ScrollController();

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Beer>> _beersFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchBeers();
  }

  Future<void> _fetchBeers() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      var response = await http.get(Uri.http('api.punkapi.com', '/v2/beers', {
        'page': currentPage.toString(),
        'per_page': perPage.toString(),
      }));
      if (response.statusCode == 200) {
        var newBeers = beerFromJson(response.body);
        setState(() {
          beers.addAll(newBeers);
          currentPage++;
          isLoading = false;
        });
      } else {
        throw Exception('Could not load beer data');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error loading more data: $error');
    }
  }

  Future<void> _refreshPage() async {
    await _fetchBeers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Beer List'),
      ),
      body: Center(
        child: RefreshIndicator(
          onRefresh: _refreshPage,
          child: FutureBuilder<List<Beer>>(
            future: _beersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                var data = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: beers.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < beers.length) {
                      var beer = beers[index];
                      return Container(
                        margin: EdgeInsets.all(9.0),
                        padding: EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white54,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 7,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BeerDetailsPage(beerId: beer.id),
                              ),
                            );
                          },
                          title: Text(
                            beer.name,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            beer.tagline,
                            style: TextStyle(color: Colors.black),
                          ),
                          leading: Image.network(beer.imageUrl),
                        ),
                      );
                    } else if (isLoading) {
                      return Center(child: CircularProgressIndicator());
                    } else {
                      return Center(child: Text('End of list'));
                    }
                  },
                );
              } else {
                return const Text('No data available');
              }
            },
          ),
        ),
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _fetchBeers();
    };
  }
}