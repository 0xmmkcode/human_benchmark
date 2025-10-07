import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import '../utils/register_view_factory_stub.dart'
    if (dart.library.html) '../utils/register_view_factory_web.dart';
import 'package:human_benchmark/web/widgets/app_loading.dart';

class WebAdBanner extends StatefulWidget {
  final double height;
  final String? position;

  const WebAdBanner({super.key, required this.height, this.position});

  @override
  State<WebAdBanner> createState() => _WebAdBannerState();
}

class _WebAdBannerState extends State<WebAdBanner> {
  static bool _scriptInjected = false;
  static int _adCounter = 0;
  static int _factoryCounter = 0;

  bool _isLoading = true;
  int _buildCount = 0;
  String? _viewType;

  @override
  void initState() {
    super.initState();
    print(
      '[AdSense] WebAdBanner initialized - Position: ${widget.position}, Height: ${widget.height}px, Initial Loading State: $_isLoading',
    );

    if (!kIsWeb) {
      print('[AdSense] Not running on web platform');
      return;
    }

    _ensureAdsScriptInjected();
    _createAdHostView();

    // Set a timeout to stop showing loading after 10 seconds
    Future.delayed(Duration(seconds: 10), () {
      if (mounted) {
        print(
          '[AdSense] Loading timeout reached for position: ${widget.position}',
        );
        setState(() {
          _isLoading = false;
        });
        print('[AdSense] Loading state changed to: $_isLoading (10s timeout)');
      }
    });
  }

  void _ensureAdsScriptInjected() {
    if (_scriptInjected) {
      print('[AdSense] Script already injected');
      return;
    }

    // Prefer the script placed in index.html/index_web.html. If present, do not inject again.
    final existing = html.document.getElementById('adsbygoogle-js');
    if (existing != null) {
      _scriptInjected = true;
      print('[AdSense] Found existing AdSense script in head');
      return;
    }

    try {
      print('[AdSense] Injecting AdSense script...');
      final script = html.ScriptElement()
        ..id = 'adsbygoogle-js'
        ..async = true
        ..defer = true
        ..src =
            'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-7825069888597435'
        ..setAttribute('crossorigin', 'anonymous');

      // Add development mode override
      if (!kReleaseMode) {
        print('[AdSense] Development mode - adding test mode attributes');
        script.setAttribute('data-adtest', 'on');
      } else {
        print('[AdSense] Production mode - using live AdSense configuration');
      }

      html.document.head?.append(script);
      _scriptInjected = true;
      print('[AdSense] ✅ AdSense script injected successfully');

      script.onLoad.listen((_) {
        print('[AdSense] 🎉 AdSense script loaded successfully!');
      });
      script.onError.listen((_) {
        print('[AdSense] ❌ AdSense script failed to load');
      });
    } catch (e) {
      print('[AdSense] ❌ Failed to inject AdSense script: $e');
    }
  }

  void _createAdHostView() {
    try {
      final int counter = _factoryCounter++;
      final String adId =
          'adsense-ad-${widget.position ?? 'default'}-${_adCounter++}';
      final String viewType = 'adsense-banner-${counter}-${adId}';

      registerViewFactory(viewType, (int viewId) {
        final html.DivElement container = html.DivElement()
          ..id = adId
          ..style.width = '100%'
          ..style.height = '${widget.height}px'
          ..style.display = 'block'
          ..style.margin = '16px 0';

        final html.Element insElement = html.Element.tag('ins')
          ..classes.add('adsbygoogle')
          ..setAttribute('style', 'display:block')
          ..setAttribute('data-ad-client', 'ca-pub-7825069888597435')
          ..setAttribute('data-ad-slot', '8029901045')
          ..setAttribute('data-ad-format', 'auto')
          ..setAttribute('data-full-width-responsive', 'true');

        if (!kReleaseMode) {
          print('[AdSense] Development mode - adding test mode to ad element');
          insElement.setAttribute('data-adtest', 'on');
        }

        container.append(insElement);

        // Explicitly request an ad fill
        _pushAdsByGoogle();

        // Start basic load detection (best-effort)
        _checkAdLoaded(adId);

        return container;
      });

      setState(() {
        _viewType = viewType;
      });
    } catch (e) {
      print('[AdSense] ❌ Failed to create AdSense host view: $e');
    }
  }

  void _pushAdsByGoogle() {
    try {
      // Ensure global exists then push a fill request
      // ignore: avoid_dynamic_calls
      (html.window as dynamic).adsbygoogle ??= [];
      // ignore: avoid_dynamic_calls
      (html.window as dynamic).adsbygoogle.push({});
    } catch (_) {
      // no-op
    }
  }

  void _checkAdLoaded(String adId) {
    print('[AdSense] Starting ad load detection for: $adId');
    int checkCount = 0;

    // Check periodically if the ad has loaded
    Timer.periodic(Duration(seconds: 1), (timer) {
      checkCount++;
      print(
        '[AdSense] Checking ad load status (attempt $checkCount) for: $adId',
      );

      if (!mounted) {
        print('[AdSense] Widget unmounted, stopping ad detection for: $adId');
        timer.cancel();
        return;
      }

      try {
        final adElement = html.document.getElementById(adId);
        if (adElement != null) {
          print('[AdSense] Ad element found in DOM: $adId');
          print(
            '[AdSense] Ad element children count: ${adElement.children.length}',
          );

          // Check if the ad has content (indicating it's loaded)
          final hasContent =
              adElement.children.isNotEmpty &&
              adElement.children.any(
                (child) =>
                    (child as html.HtmlElement).text?.trim().isNotEmpty == true,
              );

          print('[AdSense] Ad has content: $hasContent');

          if (hasContent && _isLoading) {
            print(
              '[AdSense] ✅ Ad loaded successfully! Hiding loading indicator for: $adId',
            );
            setState(() {
              _isLoading = false;
            });
            print('[AdSense] Loading state changed to: $_isLoading');
            timer.cancel();
          } else if (checkCount >= 10) {
            print(
              '[AdSense] ⏰ Ad detection timeout after 10 seconds for: $adId',
            );
            if (_isLoading) {
              setState(() {
                _isLoading = false;
              });
              print(
                '[AdSense] Loading state changed to: $_isLoading (timeout)',
              );
            }
            timer.cancel();
          }
        } else {
          print('[AdSense] ⚠️ Ad element not found in DOM: $adId');
        }
      } catch (e) {
        print('[AdSense] ❌ Error checking ad load status: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ads removed: render nothing to remove ad placements safely
    return const SizedBox.shrink();
  }

  Widget _buildLoadingOverlay() {
    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(child: AppLoading(width: 40, height: 40)),
    );
  }

  Widget _buildPlaceholder() {
    print('[AdSense] Building placeholder container');
    return Container(
      width: double.infinity,
      height: widget.height,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
    );
  }
}
