import 'package:flutter/material.dart';

//只能在pageview ，tabbarview中使用
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  final bool keepAlive;
  const KeepAliveWrapper(
      {super.key, required this.child, this.keepAlive = true});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(
        context); //必须添加,否则报错,因为AutomaticKeepAliveClientMixin没有实现build方法,所以需要手动调用,
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
