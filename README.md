# cordova-plugin-admob #
This is the AdMob Cordova Plugin. It provides a way to request AdMob ads natively from JavaScript. 

Required:
* Cordova, >=3.0

Platform SDK supported:
* iOS, using AdMob SDK for iOS, v6.10.0
* Android, using Google Play Service for Android, v4.4
* Windows Phone, using AdMob SDK for Windows Phone 8, v6.5.11

## See Also ##
Besides using Google AdMob, you have some other options, all working on cordova:
* [cordova-plugin-iad](https://github.com/floatinghotpot/cordova-plugin-iad), Apple iAd service. 
* [cordova-plugin-flurry](https://github.com/floatinghotpot/cordova-plugin-flurry), Flurry Ads service.

## How to use? ##
To install this plugin, follow the [Command-line Interface Guide](http://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-line%20Interface).

    cordova plugin add https://github.com/floatinghotpot/cordova-plugin-admob.git
    
Or,

    cordova plugin add com.rjfun.cordova.plugin.admob

Note: ensure you have a proper AdMob account and create an Id for your app.

## Quick example with cordova CLI ##
    cordova create testadmob com.rjfun.testadmob TestAdmob
    cd testadmob
    cordova platform add android
    cordova platform add ios
    // no need to manually add dependent plugin, cordova will handle it automatically
    cordova plugin add com.rjfun.cordova.plugin.admob
    rm -r www/*;
    cp plugins/com.rjfun.cordova.plugin.admob/test/index.html www/
    cordova prepare; cordova run android; cordova run ios;
    // or import into Xcode / eclipse

## Javascript API ##

APIs:
```javascript
setOptions(options, success, fail);

createBannerView(options, success, fail);
requestAd(options, success, fail);  // optional, will be absolete
showAd(true/false, success, fail); 
destroyBannerView();

createInterstitialView(options, success, fail);
requestInterstitialAd(options, success, fail); // optional, will be absolete
showInterstitialAd();
```

Events: 
- onReceiveAd, onFailedToReceiveAd, onPresentAd, onDismissAd, onLeaveToAd
- onReceiveInterstitialAd, onPresentInterstitialAd, onDismissInterstitialAd

## Example code ##
Call the following code inside onDeviceReady(), because only after device ready you will have the plugin working.
```javascript
     function onDeviceReady() {
        initAd();

        // display a banner at startup
        window.plugins.AdMob.createBannerView();
        
        // prepare the interstitial
        window.plugins.AdMob.createInterstitialView();
        
        // somewhere else, show the interstital, not needed if set autoShow = true
        window.plugins.AdMob.showInterstitialAd();
    }
    function initAd(){
        if ( window.plugins && window.plugins.AdMob ) {
            var admob_ios_key = 'ca-app-pub-6869992474017983/4806197152';
            var admob_android_key = 'ca-app-pub-6869992474017983/9375997553';
            var admobid = (( /(android)/i.test(navigator.userAgent) ) ? admob_android_key : admob_ios_key);
            window.plugins.AdMob.setOptions( {
                publisherId: admobid,
                bannerAtTop: false, // set to true, to put banner at top
                overlap: false, // set to true, to allow banner overlap webview
                offsetTopBar: false, // set to true to avoid ios7 status bar overlap
                isTesting: true, // receiving test ad
                autoShow: true // auto show interstitial ad when loaded
            });

            registerAdEvents();
            
        } else {
            alert( 'admob plugin not ready' );
        }
    }
	// optional, in case respond to events
    function registerAdEvents() {
    	document.addEventListener('onReceiveAd', function(){});
        document.addEventListener('onFailedToReceiveAd', function(data){});
        document.addEventListener('onPresentAd', function(){});
        document.addEventListener('onDismissAd', function(){ });
        document.addEventListener('onLeaveToAd', function(){ });
        document.addEventListener('onReceiveInterstitialAd', function(){ });
        document.addEventListener('onPresentInterstitialAd', function(){ });
        document.addEventListener('onDismissInterstitialAd', function(){ });
    }
```

See the working example code in [demo under test folder](test/index.html), and here are some screenshots.
 
## Screenshots (banner Ad / interstitial Ad) ##

iPhone:

![ScreenShot](admob-iphone.jpg)

iPad, landscape:

![ScreenShot](admob-ipad-landscape.jpg)

Android:

![ScreenShot](admob-android.jpg)


## Donate ##
You can use this cordova plugin for free. To support this project, donation is welcome.  
Donation can be accepted in either of following ways:
* Share 2% Ad traffic. 
* [Donate directly via Paypal](http://floatinghotpot.github.io/#donate)

