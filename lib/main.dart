import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_transform/stream_transform.dart';

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

  StreamSubscription _stream;
  StreamController<double> _controller = new StreamController<double>.broadcast();

  final List<Tab> myTabs = <Tab>[
    new Tab(text: 'FIRST'),
    new Tab(text: 'SECOND'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(vsync: this, length: myTabs.length);

    _stream = _controller.stream.transform(debounce(new Duration(milliseconds: 500))).listen(_saveState);
  }

  void _saveState(double value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('listViewOffset', value);
  }

  void _setOffset(double offset) {
    this.listViewOffset = offset;
    _controller.add(offset);
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
          setOffsetMethod: _setOffset,
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

  @override
  void dispose() {
    _stream.cancel();
    super.dispose();
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

    _restoreState().then((double value) => scrollController.jumpTo(value));
  }

  Future<double> _restoreState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('listViewOffset');
  }

  void setScroll(double value) {
    setState(() {
      scrollController.jumpTo(value);
    });
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