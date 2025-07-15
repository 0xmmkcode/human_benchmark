import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:human_benchmark/ad_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(MaterialApp(home: ReactionTimePage(), debugShowCheckedModeBanner: false,));
}

class ReactionTimePage extends StatefulWidget {
  @override
  _ReactionTimePageState createState() => _ReactionTimePageState();
}

enum GameState { ready, waiting, go, result }

class _ReactionTimePageState extends State<ReactionTimePage> {
  late BannerAd _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  int _roundCounter = 0;

  bool _isBannerAdReady = false;
  GameState _state = GameState.ready;
  Timer? _timer;
  DateTime? _startTime;
  int? _reactionTime;
  int? _highScore;
  final Random _random = Random();
  final Color backgroundColor = Color(0xFF0074EB);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadHighScore();
    _loadInterstitialAd();

    //ca-app-pub-7825069888597435/7877550006
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      // Replace with your Ad Unit ID
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Banner failed to load: $err');
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _interstitialAd?.dispose();
    _bannerAd.dispose();
    super.dispose();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId, // Replace with your own ad unit
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Interstitial failed to load: $error');
          _isAdLoaded = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  void _startGame() {
    setState(() {
      _state = GameState.waiting;
      _reactionTime = null;
    });

    int delay = 2000 + _random.nextInt(3000); // 2 to 5 seconds
    _timer = Timer(Duration(milliseconds: delay), () {
      setState(() {
        _state = GameState.go;
        _startTime = DateTime.now();
      });
    });
  }

  void _onScreenTap() async {
    _roundCounter++;

    if (_roundCounter % 5 == 0 && _isAdLoaded) {
      _interstitialAd?.show();
      _interstitialAd = null;
      _isAdLoaded = false;
      _loadInterstitialAd(); // load the next ad for future use
    }
    if (_state == GameState.waiting) {
      _timer?.cancel();
      setState(() {
        _state = GameState.result;
        _reactionTime = -1; // Too early
      });
    } else if (_state == GameState.go) {
      final now = DateTime.now();

      setState(() {
        _state = GameState.result;
        _reactionTime = now
            .difference(_startTime!)
            .inMilliseconds;
      });
      if (_reactionTime == null || _reactionTime! < (_highScore ?? 999999)) {
        _highScore = _reactionTime;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('highScore', _highScore!);
      }
    } else if (_state == GameState.result) {
      setState(() {
        _state = GameState.ready;
      });
    }
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('highScore');
    });
  }

  @override
  Widget build(BuildContext context) {
    String message = '';
    Color bgColor = backgroundColor;

    switch (_state) {
      case GameState.ready:
        message = 'Tap to Start';
        break;
      case GameState.waiting:
        message = 'Wait for Green...';
        bgColor = Colors.red;
        break;
      case GameState.go:
        message = 'TAP NOW!';
        bgColor = Colors.green;
        break;
      case GameState.result:
        if (_reactionTime == -1) {
          message = 'Too Soon!\nTap to Try Again';
          bgColor = Colors.red.shade900;
        } else {
          message = 'Your Reaction Time: $_reactionTime ms\nTap to Retry';
          bgColor = Colors.blueGrey;
        }
        break;
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          return SafeArea(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_state == GameState.ready) {
                      _startGame();
                    } else {
                      _onScreenTap();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.only(
                        top: 70, left: 20, right: 20, bottom: 20),
                    decoration: BoxDecoration(color: bgColor),
                    height: constraints.maxHeight * 0.8,
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/images/human_logo_white.png",
                          height: 40,
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30)
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset("assets/images/trophy-star.png", height: 30,),
                              Gap(10),
                              Text(
                                '${_highScore ?? "--"} ms',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _isBannerAdReady ? Container(
                    height: _bannerAd.size.height.toDouble(),
                    width: _bannerAd.size.width.toDouble(),
                    child: AdWidget(ad: _bannerAd),
                  ): null,
                )
              ],
            ),
          );
        },
      ),
    );
    return GestureDetector(
      onTap: () {
        if (_state == GameState.ready) {
          _startGame();
        } else {
          _onScreenTap();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_highScore != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '🏆 Best: $_highScore ms',
                  style: TextStyle(fontSize: 20, color: Colors.white70),
                ),
              ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
