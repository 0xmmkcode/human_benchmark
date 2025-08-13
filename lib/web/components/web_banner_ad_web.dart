import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;
// ignore: unused_import
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/register_view_factory_stub.dart'
    if (dart.library.html) '../utils/register_view_factory_web.dart';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';

class WebBannerAd extends StatefulWidget {
  final double height;

  const WebBannerAd({super.key, this.height = 90});

  @override
  State<WebBannerAd> createState() => _WebBannerAdState();
}

class _WebBannerAdState extends State<WebBannerAd> {
  static bool _scriptInjected = false;
  static int _factoryCounter = 0;
  String? _viewType;

  // AdMob publisher and ad unit provided by user. For web, the script expects
  // the AdSense-format client id (ca-pub-...). AdMob publisher id is reused.
  static const String _adsenseClient = 'ca-pub-7825069888597435';
  static const String _adSlot = '7877550006';

  @override
  void initState() {
    super.initState();
    if (!kReleaseMode) return;

    _ensureAdsScriptInjected();

    final int counter = _factoryCounter++;
    final String viewType =
        'admob-banner-${_adSlot}-${counter}-${math.Random().nextInt(1 << 32)}';

    registerViewFactory(viewType, (int viewId) {
      final html.DivElement container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '${widget.height}px'
        ..style.overflow = 'hidden';

      final html.Element ins = html.Element.tag('ins')
        ..classes.add('adsbygoogle')
        ..style.display = 'block'
        ..style.width = '100%'
        ..style.height = '${widget.height}px'
        ..setAttribute('data-ad-client', _adsenseClient)
        ..setAttribute('data-ad-slot', _adSlot)
        ..setAttribute('data-ad-format', 'auto')
        ..setAttribute('data-full-width-responsive', 'true');

      container.append(ins);

      // Trigger the ad fill once the script is available
      unawaited(_pushAdsByGoogle());

      return container;
    });

    setState(() {
      _viewType = viewType;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kReleaseMode) return const SizedBox.shrink();
    if (_viewType == null) {
      return SizedBox(height: widget.height);
    }
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: HtmlElementView(viewType: _viewType!),
    );
  }

  void _ensureAdsScriptInjected() {
    if (_scriptInjected) return;

    final existing = html.document.getElementById('adsbygoogle-js');
    if (existing != null) {
      _scriptInjected = true;
      return;
    }

    final html.ScriptElement script = html.ScriptElement()
      ..id = 'adsbygoogle-js'
      ..async = true
      ..defer = true
      ..src =
          'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=$_adsenseClient'
      ..setAttribute('crossorigin', 'anonymous');

    html.document.head?.append(script);
    _scriptInjected = true;
  }

  Future<void> _pushAdsByGoogle() async {
    // Wait briefly to ensure the global is ready
    await Future<void>.delayed(const Duration(milliseconds: 200));
    try {
      final dynamic w = html.window;
      if (w.adsbygoogle == null) {
        // ignore: avoid_dynamic_calls
        w.adsbygoogle = [];
      }
      // ignore: avoid_dynamic_calls
      w.adsbygoogle.push({});
    } catch (_) {
      // noop
    }
  }
}
