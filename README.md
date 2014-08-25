# cordova-plugin-admob #

AdMob Cordova Plugin, provides a way to request AdMob ads natively from JavaScript. 

# Notice #

[AdMob Plugin Pro](https://github.com/floatinghotpot/cordova-admob-pro) is more recommended, which is the enhanced version of this plugin. 

Highlights:
- [x] Support Banner Ad and Interstitial Ad.
- [x] Multiple banner size, also support custom size.
- [x] Fixed and overlapped mode.
- [x] Most flexible, put banner at any position with overlap mode.
- [x] Auto fit on orientation change.
- [x] Latest iOS SDK v6.11.1, 
- [x] Latest Android Google play services r19.
- [x] Compatible with Intel XDK and Crosswalk.
- [x] Easy-to-use APIs. Can display Ad with single line of Js code.
- [x] Actively maintained, prompt support.

Tips: (According to history stat data in past 2 months)
- [x] Using AdMob Plugin Pro, will get higher fill rate.
- [x] Using Interstitial, will earn better profit, RPM 10 times higher than Banner. 

News:
- Recommended by Verified Plugins Marketplace. [read more ...](http://plugins.telerik.com/plugin/admob)
- Recommended by William SerGio in code project (20 Jun 2014), [read more ...](http://www.codeproject.com/Articles/788304/AdMob-Plugin-for-Latest-Version-of-PhoneGap-Cordov)
- Recommended by Arne in Scirra Game Dev Forum (07 Aug, 2014), [read more ...](https://www.scirra.com/forum/plugin-admob-ads-for-crosswalk_t111940)
- Recommended by Intel XDK team (08/22/2014), [read more ...](https://software.intel.com/en-us/html5/articles/adding-google-play-services-to-your-cordova-application)

More Cordova plugins by Raymond Xie, [click here](http://floatinghotpot.github.io/).

Will this project continue? Yes. This project will continue to be maintained and supported.

## See Also ##

* [AdMob Plugin Pro](https://github.com/floatinghotpot/cordova-admob-pro), enhanced AdMob plugin, more flexible, multiple size, any position, friendly APIs.
* [cordova-plugin-iad](https://github.com/floatinghotpot/cordova-plugin-iad), Apple iAd service. 
* [cordova-plugin-flurry](https://github.com/floatinghotpot/cordova-plugin-flurry), Flurry Ads service.

More Cordova/PhoneGap plugins by Raymond Xie, [click here](http://floatinghotpot.github.io/).

## Platform SDK supported ##

* iOS, using AdMob SDK for iOS, v6.10.0
* Android, using Google Play Service for Android, v4.4
* Windows Phone, using AdMob SDK for Windows Phone 8, v6.5.11

## How to use? ##
To install this plugin, follow the [Command-line Interface Guide](http://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-line%20Interface).

    cordova plugin add https://github.com/floatinghotpot/cordova-plugin-admob.git
    
Or,

    cordova plugin add com.rjfun.cordova.plugin.admob

Note: ensure you have a proper AdMob account and create an Id for your app.

## Quick example with cordova CLI ##
```c
    cordova create <project_folder> com.<company_name>.<app_name> <AppName>
    cd <project_folder>
    cordova platform add android
    cordova platform add ios

    // cordova will handle dependency automatically
    cordova plugin add com.rjfun.cordova.plugin.admob

    // now remove the default www content, copy the demo html file to www
    rm -r www/*;
    cp plugins/com.rjfun.cordova.plugin.admob/test/index.html www/

    cordova prepare; cordova run android; cordova run ios;
    // or import into Xcode / eclipse
```

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
    	    var ad_units = {
				ios : {
					banner: 'ca-app-pub-6869992474017983/4806197152',
					interstitial: 'ca-app-pub-6869992474017983/7563979554'
				},
				android : {
					banner: 'ca-app-pub-6869992474017983/9375997553',
					interstitial: 'ca-app-pub-6869992474017983/1657046752'
				}
    	    };
            var admobid = ( /(android)/i.test(navigator.userAgent) ) ? ad_units.android : ad_units.ios;
            
            window.plugins.AdMob.setOptions( {
                publisherId: admobid.banner,
                interstitialAdId: admobid.interstitial,
                bannerAtTop: false, // set to true, to put banner at top
                overlap: false, // set to true, to allow banner overlap webview
                offsetTopBar: false, // set to true to avoid ios7 status bar overlap
                isTesting: false, // receiving test ad
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

![ScreenShot](demo/admob-iphone.jpg)

iPad, landscape:

![ScreenShot](demo/admob-ipad-landscape.jpg)

Android:

![ScreenShot](demo/admob-android.jpg)


## Donate ##
You can use this cordova plugin for free. To support this project, donation is welcome.  
Donation can be accepted in either of following ways:
* Share 2% Ad traffic. 
* [Donate directly via Paypal](http://floatinghotpot.github.io/#donate)

