import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UehNewsWebView extends StatefulWidget {
  const UehNewsWebView({super.key});

  static const _url = 'https://ueh.edu.vn/tintucmobile';

  @override
  State<UehNewsWebView> createState() => _UehNewsWebViewState();
}

class _UehNewsWebViewState extends State<UehNewsWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(UehNewsWebView._url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
