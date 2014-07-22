# cordova-plugin-admob #
This is the AdMob Cordova Plugin. It provides a way to request AdMob ads natively from JavaScript. 

It's now updated and enhanced to support:
* Cordova 3.0, 3.5.

Platform SDK supported:
* iOS, using AdMob SDK for iOS, v6.8.4 (deprecated), v6.9.3 (SDK included)
* Android, using Google Play Service for Android, v4.4 (replacing AdMob SDK for Android)
* Windows Phone, using AdMob SDK for Windows Phone 8, v6.5.11 (newly added, and SDK included)

## See Also ##
Besides using Google AdMob, you have some other options, all working on cordova:
* [cordova-plugin-iad](https://github.com/floatinghotpot/cordova-plugin-iad), Apple iAd service. 
* [cordova-plugin-flurry](https://github.com/floatinghotpot/cordova-plugin-flurry), Flurry Ads service.

## How to use? ##
To install this plugin, follow the [Command-line Interface Guide](http://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-line%20Interface).

    cordova plugin add https://github.com/floatinghotpot/cordova-plugin-admob.git

Note: ensure you have a proper AdMob account and create an Id for your app.

## Quick example with cordova command line tool ##
    cordova create testadmob com.rjfun.testadmob TestAdmob
    cd testadmob
    cordova platform add android
    cordova platform add ios
    cordova plugin add https://github.com/floatinghotpot/cordova-plugin-admob.git
    mv www www.default
    mkdir www
    cp plugins/com.rjfun.cordova.plugin.admob/test/index.html www/
    cordova prepare; cordova run android; cordova run ios;
    // or import into Xcode / eclipse

Or, just clone the testadmob project from github:

    git clone git@github.com:floatinghotpot/testadmob.git

## Javascript API ##
```javascript
   createBannerView(options, success, fail);
   requestAd(options, success, fail);
   showAd(true/false, success, fail);
   destroyBannerView();

   createInterstitialView(options, success, fail);
   requestInterstitialAd(options, success, fail);
   showInterstitialAd();
```

## Example javascript ##
Call the following code inside onDeviceReady(), because only after device ready you will have the plugin working.
```javascript
    var admob_ios_key = 'ca-app-pub-6869992474017983/4806197152';
    var admob_android_key = 'ca-app-pub-6869992474017983/9375997553';
    var adId = (/(android)/i.test(navigator.userAgent)) ? admob_android_key : admob_ios_key;
        
    if( window.plugins && window.plugins.AdMob ) {
        var am = window.plugins.AdMob;
    
        am.createBannerView( 
            {
            'publisherId': adId,
            'adSize': am.AD_SIZE.BANNER,
            'bannerAtTop': false, // set to true, to make banner at top
            'overlap': false,  // set to true, to allow banner view overlap web content instead of push up/down
            'offsetTopBar': false // set to true, to avoid ios 7 status bar overlap
            }, 
            function() {
        	    am.requestAd( { 'isTesting':true }, // set to false, for production purpose 
            		function(){}, 
            		function(){ alert('failed to request ad'); }
            		);
            }, 
            function(){ alert('failed to create banner view'); }
        );
        
        am.createInterstitialView(
              {
                  'publisherId': adId
              },
              function() {
                  am.requestInterstitialAd( { 'isTesting':true }, // set to false, for production purpose
			function() {}, 
			function() { alert('failed to request ad'); }
			);
              },
              function() {
                  alert("Interstitial failed");
              }
          );
        
    } else {
      alert('AdMob plugin not available/ready.');
    }
```

## Events ##
This plugin also allows you the option to listen for ad events. The following events are supported:
```javascript
    	// more callback to handle Ad events
    	document.addEventListener('onReceiveAd', function(){
		window.plugins.AdMob.showAd( true );
    	});
    	document.addEventListener('onFailedToReceiveAd', function(data){
    		// alert( data.error );
    	});
    	document.addEventListener('onPresentAd', function(){
    	});
    	document.addEventListener('onDismissAd', function(){
    	});
    	document.addEventListener('onLeaveToAd', function(){
    	});   

	document.addEventListener('onReceiveInterstitialAd', function(){
		window.plugins.AdMob.showInterstitialAd();
        });
	document.addEventListener('onPresentInterstitialAd', function(){
        });
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

