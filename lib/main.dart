import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pergam/firebase_options.dart';

final catalogEndpoint =
    FirebaseFirestore.instance.collection('catalog').withConverter<Item>(
          fromFirestore: (snapshot, _) =>
              Item.fromMap(snapshot.data()!, snapshot.id),
          toFirestore: (item, _) => item.toMap(),
        );

enum CatalogQuery {
  all,
  sortByMaxPrice,
  sortByMinPrice,
  filterByPens,
  filterByPencils,
  filterByPaper,
}

extension on Query<Item> {
  Query<Item> queryBy(CatalogQuery query) {
    switch (query) {
      case CatalogQuery.sortByMaxPrice:
        return orderBy('price', descending: true);
      case CatalogQuery.sortByMinPrice:
        return orderBy('price');
      case CatalogQuery.filterByPens:
        return where('group', isEqualTo: 'Ручки');
      case CatalogQuery.filterByPencils:
        return where('group', isEqualTo: 'Карандаши');
      case CatalogQuery.filterByPaper:
        return where('group', isEqualTo: 'Бумага');
      case CatalogQuery.all:
        return where('name', isNotEqualTo: null);
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseUIAuth.configureProviders([EmailAuthProvider()]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var providers = [EmailAuthProvider()];
    return MaterialApp(
      initialRoute:
          FirebaseAuth.instance.currentUser == null ? '/auth' : '/home',
      routes: {
        '/auth': (context) {
          return SignInScreen(
            providers: providers,
            actions: [
              AuthStateChangeAction<SignedIn>(
                (context, state) {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
            ],
          );
        },
        '/profile': (context) => ProfileScreen(
              providers: providers,
              actions: [
                SignedOutAction((context) {
                  Navigator.pushReplacementNamed(context, '/auth');
                })
              ],
            ),
        '/home': (context) => CatalogPage()
      },
      title: 'Pergam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
    );
  }
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({Key? key}) : super(key: key);

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  var query = CatalogQuery.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text(
                'Pergam',
                style: TextStyle(
                  fontSize: 45,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ListTile(
              title: const Text('About Us'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OtherPage(
                      title: 'About Us',
                      description:
                          'kfaljdfkljafkldjsafkljdsaklf fkdjakld jfklaj'),
                ),
              ),
            ),
            ListTile(
              title: const Text('News'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OtherPage(
                      title: 'News',
                      description:
                          'kfaljdfkljafkldjsafkljdsaklf fkdjakld jfklaj'),
                ),
              ),
            ),
            ListTile(
              title: const Text('Contacts'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OtherPage(
                      title: 'Contacts',
                      description:
                          'kfaljdfkljafkldjsafkljdsaklf fkdjakld jfklaj'),
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Pergam'),
        centerTitle: false,
        actions: [
          PopupMenuButton(
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: CatalogQuery.all,
                child: Text('Show All'),
              ),
              const PopupMenuItem(
                value: CatalogQuery.sortByMinPrice,
                child: Text('Sort by Min Price'),
              ),
              const PopupMenuItem(
                value: CatalogQuery.sortByMaxPrice,
                child: Text('Sort by Max Price'),
              ),
              const PopupMenuItem(
                value: CatalogQuery.filterByPens,
                child: Text('Filter by Pens'),
              ),
              const PopupMenuItem(
                value: CatalogQuery.filterByPencils,
                child: Text('Filter by Pencils'),
              ),
              const PopupMenuItem(
                value: CatalogQuery.filterByPaper,
                child: Text('Filter by Paper'),
              ),
            ],
            onSelected: (value) => setState(() => query = value),
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            onPressed: () {
              showSearch(
                context: context,
                delegate: SearchWidget([], context),
              );
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Item>>(
        stream: catalogEndpoint.queryBy(query).snapshots(),
        builder: (_, snap) {
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString()));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final finalItems = snap.requireData;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10),
            itemBuilder: (ctx, i) => ItemWidget(
              item: finalItems.docs[i].data(),
            ),
            itemCount: finalItems.size,
          );
        },
      ),
    );
  }
}

class OtherPage extends StatelessWidget {
  final String title;
  final String description;

  const OtherPage({Key? key, required this.title, required this.description})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(description),
      ),
    );
  }
}

class Item {
  final String id;
  final String image;
  final String name;
  final String group;
  final int price;
  final int? quantity;
  final String? description;
  final String? code;
  final int? barcode;

  Item({
    required this.id,
    required this.image,
    required this.name,
    required this.group,
    required this.price,
    this.quantity,
    this.description,
    this.code,
    this.barcode,
  });

  Item.fromMap(Map<String, dynamic> data, String id)
      : this(
          id: id,
          name: data['name'] ?? '',
          image: data['image'] ?? '',
          group: data['group'] ?? '',
          price: data['price'] ?? 0,
        );

  Map<String, dynamic> toMap() => {
        'id': id,
        'image': image,
        'name': name,
        'group': group,
        'price': price,
        'quantity': quantity,
        'description': description,
        'code': code,
        'barcode': barcode,
      };
}

class SearchWidget extends SearchDelegate<Item?> {
  final List<Item> items;
  final BuildContext context;

  SearchWidget(this.items, this.context);

  var tempItems = <Item>[];

  @override
  String? get searchFieldLabel => 'Search';

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          onPressed: () {
            query = '';
          },
          icon: const Icon(Icons.clear),
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        onPressed: () {
          close(context, null);
        },
        icon: const Icon(Icons.arrow_back),
      );

  @override
  Widget buildResults(BuildContext context) => ListView.builder(
        itemBuilder: (ctx, i) => ItemWidget(item: tempItems[i]),
        itemCount: tempItems.length,
      );

  @override
  Widget buildSuggestions(BuildContext context) {
    tempItems = items
        .where(
          (item) => item.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return ListView.builder(
      itemBuilder: (ctx, i) => ItemWidget(item: tempItems[i]),
      itemCount: tempItems.length,
    );
  }
}

class ItemWidget extends StatelessWidget {
  final Item item;

  const ItemWidget({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => ItemPage(item: item),
            ),
          );
        },
        child: GridTile(
          header: GridTileBar(
            backgroundColor: Theme.of(context).primaryColor,
            title: Text(
              item.name,
            ),
          ),
          footer: GridTileBar(
            backgroundColor: Theme.of(context).primaryColor,
            title: Text(
              item.price.toString(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          child: Image.network(
            item.image,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class ItemPage extends StatelessWidget {
  final Item item;

  const ItemPage({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Image.network(item.image),
            const SizedBox(height: 10),
            Text(item.group),
            const SizedBox(height: 10),
            Text(item.price.toString()),
            const SizedBox(height: 10),
            Text(item.barcode.toString()),
          ],
        ),
      ),
    );
  }
}
