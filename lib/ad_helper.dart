class AdHelper {
  static bool get _isTest => bool.fromEnvironment("dart.vm.product") == false;

  static String get bannerAdUnitId {
    return _isTest
        ? 'ca-app-pub-3940256099942544/6300978111' // test banner
        : 'ca-app-pub-7825069888597435/7877550006'; // real one
  }

  static String get interstitialAdUnitId {
    return _isTest
        ? 'ca-app-pub-3940256099942544/1033173712' // test interstitial
        : 'ca-app-pub-7825069888597435/3815155680'; // real one
  }

  static String get rewardedAdUnitId {
    return _isTest
        ? 'ca-app-pub-3940256099942544/5224354917' // test rewarded
        : 'ca-app-pub-xxxxxxxxxxxxxxxx/yourRewardedId';
  }
}
