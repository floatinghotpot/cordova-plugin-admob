## Cordova Plugin for AdMob, Open Source Project

The FASTEST and EASIEST TO USE Cordova Admob plugin for Android, iOS and Windows phone.

Simple and easy plugin to monetize your HTML5 hybrid apps and games.

Usage:
- Create your app

```bash
cordova create hallo com.example.hello HelloWorld
cd hallo
cordova platform add android
```

- Add the plugin
```bash
cordova plugin add cordova-plugin-admob
```

OR
```bash
cordova plugin add https://github.com/floatinghotpot/cordova-plugin-admob
```

Example Code:
```javascript
        window.plugins.AdMob.setOptions( {
          publisherId: admobid.banner,
          interstitialAdId: admobid.interstitial,
          bannerAtTop: false, // set to true, to put banner at top
          overlap: false, // set to true, to allow banner overlap webview
          offsetTopBar: false, // set to true to avoid ios7 status bar overlap
          isTesting: false, // receiving test ad
          autoShow: true // auto show interstitial ad when loaded
        });
        // display the banner at startup
        window.plugins.AdMob.createBannerView();
        
        // create interstitial ad
        window.plugins.AdMob.createInterstitialView();
        window.plugins.AdMob.showInterstitialAd(
          true, 
          function(){},
          function(e){alert(JSON.stringify(e));}
        );
```

See full index.html: https://github.com/floatinghotpot/cordova-plugin-admob/blob/master/test/index.html

Note: This plugin is quite stable, and will not be evolved any more, except upgrade AdMob SDK.

## AdMob Basic vs Pro

If you want to use more powerful and new features, please use the pro version instead. The totoally re-designed **[AdMob PluginPro](https://github.com/floatinghotpot/cordova-admob-pro)** is proved much better and more than welcome by Cordova APP/game developers. 

As announced by Cordova team, the plugins registry is being migrated to npm, you can find [all plugins by Raymond here](https://www.npmjs.com/~floatinghotpot).

![ScreenShot](https://github.com/floatinghotpot/cordova-plugin-admob/raw/master/docs/pro_vs_basic.png)

## Credits

This plugin was mainly maintained by Raymond Xie, and also thanks to following contributors:

* @jumin-zhu, added interstitial support for Android.
* @fersingb, added interstitial support for iOS.
* @ihshim523, added initial WP8 support.
* @AlexB71, improved WP8 support.
* And, bugfix patches from @chrisschaub, @jmelvin, @mbektchiev, @grahamkennery, @bastaware, @EddyVerbruggen, @codebykevin, @codebykevin, @zahhak.

This project is fully open source, and no ad traffic sharing any more.

## More

More free projects by Raymond Xie, find them on npm: 
https://www.npmjs.com/~floatinghotpot



