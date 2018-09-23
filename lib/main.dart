import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef double GetOffsetMethod();
typedef void SetOffsetMethod(double offset);

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {

  double listViewOffset=0.0;

  TabController _tabController;

  final List<Tab> myTabs = <Tab>[
    new Tab(text: 'FIRST'),
    new Tab(text: 'SECOND'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(vsync: this, length: myTabs.length);

    _restoreState().then(setScroll);
  }

  @override
  void dispose() {
    _saveState();
    super.dispose();
  }

  Future<double> _restoreState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('listViewOffset');
  }

  void _saveState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('listViewOffset', listViewOffset);
  }

  void setScroll(double value) {
    this.setState(() => listViewOffset = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text('Sample app'),
    ),
    body: new TabBarView(
        controller: _tabController,
        children: [new ListTab(
          getOffsetMethod: () => listViewOffset,
          setOffsetMethod: (offset) => this.listViewOffset = offset,
        ),
          Text('Second tab'),
        ],),
      bottomNavigationBar: new TabBar(
        controller: _tabController,
        tabs: myTabs,
        labelColor: Colors.blue,
      ),
    );
  }
}

class ListTab extends StatefulWidget {

  ListTab({Key key, this.getOffsetMethod, this.setOffsetMethod}) : super(key: key);

  final GetOffsetMethod getOffsetMethod;
  final SetOffsetMethod setOffsetMethod;

  @override
  _ListTabState createState() => _ListTabState();
}

class _ListTabState extends State<ListTab> {

  ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    //Init scrolling to preserve it
    scrollController = new ScrollController(
        initialScrollOffset: widget.getOffsetMethod()
    );
  }

  @override
  Widget build(BuildContext context) {
    return
      NotificationListener(
        child: new ListView.builder(
          controller: scrollController,
          itemBuilder: ListData().build,
        ),
        onNotification: (notification) {
          if (notification is ScrollNotification) {
            widget.setOffsetMethod(notification.metrics.pixels);
          }
        },
      );
  }
}


class ListData {
  static ListData _instance = ListData._internal();

  ListData._internal();

  factory ListData() {
    return _instance;
  }

  Random _rand = Random();
  Map<int, int> _values = new Map();

  Widget build (BuildContext context, int index) {
    if (!_values.containsKey(index)) {
      _values[index] = _rand.nextInt(100);
    }

    return Text('Random number ${_values[index]}',);
  }
}