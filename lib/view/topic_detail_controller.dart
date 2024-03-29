import 'package:flutter/material.dart';
import 'package:flutter_html_view/flutter_html_view.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../model/topic.dart';
import '../service/network.dart';
import 'web_controller.dart';

class TopicDetailController extends StatefulWidget {
  final Topic topic;
  TopicDetailController({this.topic});
  @override
  _TopicDetailControllerState createState() =>
      _TopicDetailControllerState(topic);
}

class _TopicDetailControllerState extends State<TopicDetailController> {
  TopicDetail topic;
  InstantView instantView;
  bool showInstantView = false;
  bool get instantViewEnable => (instantView != null &&
      instantView.content != null &&
      instantView.content.length > 0);

  _TopicDetailControllerState(Topic data) {
    topic = TopicDetail(
        id: data.id,
        entityTopics: [],
        newsArray: data.newsArray,
        createdAt: data.createdAt,
        entityEventTopics: [],
        publishDate: data.publishDate,
        summary: data.summary,
        title: data.title,
        updatedAt: data.updatedAt,
        timeline: null,
        order: data.order,
        hasInstantView: false);
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Widget buildSectionTitle(IconData icon, String title) {
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 16,
          ),
          Text(
            " $title",
            style: Theme.of(context).textTheme.title.apply(fontSizeFactor: 0.9),
          )
        ],
      ),
    );
  }

  Widget _buildBody() {
    List<Widget> list = [
      Container(
          margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: double.infinity),
            child: Text.rich(TextSpan(children: [
              TextSpan(
                  text: topic.title == null ? "" : topic.title,
                  style: Theme.of(context).textTheme.title),
              TextSpan(
                  text: topic.publishDate == null
                      ? ""
                      : ("\n" +
                          timeago.format(DateTime.parse(topic.publishDate),
                              locale: 'en')),
                  style: Theme.of(context).textTheme.overline),
            ])),
          )),
    ];

    if (instantViewEnable && showInstantView) {
      list.add(HtmlView(
        data: instantView.content,
        baseURL: "",
        onLaunchFail: () {
          setState(() {
            instantView = null;
          });
        },
      ));
    } else {
      list.add(Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
        child: Text(
          topic.summary == null ? "载入中" : topic.summary,
          maxLines: null,
          style: Theme.of(context).textTheme.caption,
        ),
      ));
    }

    if (topic?.newsArray?.isNotEmpty ?? false) {
      list.add(buildSectionTitle(Icons.apps, "媒体报道"));
      for (NewsArray news in topic.newsArray) {
        list.add(Container(
          margin: EdgeInsets.only(top: 8),
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (ctx) {
                return WebController(title: news.title, url: news.url);
              }));
            },
            child: Text.rich(TextSpan(children: [
              TextSpan(
                  text: " ∙  " + news.title.replaceAll("\n", ""),
                  style: Theme.of(context).textTheme.subhead),
              TextSpan(
                  text: "  " + news.siteName,
                  style: Theme.of(context).textTheme.overline),
            ])),
          ),
        ));
      }
    }

    if (topic.timeline?.topics?.isNotEmpty ?? false) {
      list.add(Container(
        margin: EdgeInsets.only(top: 10),
        child: buildSectionTitle(Icons.all_inclusive, "相关事件"),
      ));
      List<Widget> timeline = [];
      for (TopicSimple tp in topic.timeline.topics) {
        timeline.add(Container(
          margin: EdgeInsets.only(top: 8),
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (ctx) {
                return TopicDetailController(
                  topic: Topic(id: tp.id, title: tp.title),
                );
              }));
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: double.infinity),
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: " ∙  " + tp.title.replaceAll("\n", ""),
                    style: Theme.of(context).textTheme.subhead),
                TextSpan(
                    text: "  " + timeago.format(DateTime.parse(tp.createdAt)),
                    style: Theme.of(context).textTheme.overline),
              ])),
            ),
          ),
        ));
      }
      list.add(Container(
        margin: EdgeInsets.only(top: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black12
                    : Colors.white12,
                width: 1,
              )),
          child: Container(
            margin: EdgeInsets.fromLTRB(8, 2, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: timeline,
            ),
          ),
        ),
      ));
    }

    return Container(
      color: Theme.of(context).cardColor,
      child: ListView(
        padding: EdgeInsets.all(20),
        children: list,
      ),
    );
  }

  List<Widget> buildActions() {
    if (instantViewEnable) {
      return [
        FlatButton(
            onPressed: () {
              setState(() {
                showInstantView = !showInstantView;
              });
            },
            child: Text(
              "原",
              style: TextStyle(
                  color: showInstantView ? Colors.white : Colors.white30),
            ))
      ];
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(topic.title),
        actions: buildActions(),
      ),
      body: _buildBody(),
    );
  }

  loadData() {
    if (topic?.id != null) {
      Network.shared.getDetail(topic.id).then((value) {
        value.title =
            value.title.replaceAll(RegExp(r"[\n\r]*$", multiLine: true), "");
        value.summary =
            value.summary.replaceAll(RegExp(r"[\n\r]*$", multiLine: true), "");
        setState(() {
          topic = value;
        });
      });
      Network.shared.getInstantView(topic.id).then((value) {
        setState(() {
          instantView = value;
        });
      });
    }
  }
}
