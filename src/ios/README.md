AdMob Cordova Plugin for iOS
================================

This is the AdMob Cordova Plugin for iOS.  It provides a way to request AdMob ads natively from JavaScript.  

##Requirements:

- Cordova SDK for iOS
- Cordova JS for iOS
- An AdMob site ID or DoubleClick for Publishers account.
- Xcode 5.1 or later.
- Runtime of iOS 5.0 or later.
- Google AdMob Ads SDK for iOS (version 6.9.3 already included)

The SDK can also be downloaded at:
https://developers.google.com/mobile-ads-sdk/download#downloadios

##Setup:

1. It's recommended to use cordova command line tool to manage the plugin like this:
   cordova plugin add https://github.com/floatinghotpot/cordova-plugin-admob.git
   
2. Import Cordova SDK binary and Google AdMob SDK binary into your project (with
   their associated header files).
   
The latest documentation and code samples are available at:
https://developers.google.com/mobile-ads-sdk/docs/

##Implementation:

##Using the Plugin:

There are 3 calls needed to get AdMob Ads:

1. `createBannerView`

   Takes in a object containing a publisherId and adSize, as well as success
   and failure callbacks.  An example call is provided below:

        window.AdMob.createBannerView(
             {
               'publisherId': 'INSERT_YOUR_PUBLISHER_ID_HERE',
               'adSize': AdSize.BANNER
             },
             successCallback,
             failureCallback
         );

2. `requestAd`

   Takes in an object containing an optional testing flag, and an optional
   list of extras.  This method should only be invoked once createBannerView
   has invoked successCallback.  An example call is provided below:

         window.AdMob.requestAd(
             {
               'isTesting': false,
               'extras': {
                 'color_bg': 'AAAAFF',
                 'color_bg_top': 'FFFFFF',
                 'color_border': 'FFFFFF',
                 'color_link': '000080',
                 'color_text': '808080',
                 'color_url': '008000'
               },
             },
             successCallback,
             failureCallback
         );


3. `showAd`

   Show or hide the Ad.
   
   This method should only be invoked once createBannerView has invoked successCallback.  
   An example call is provided below:

         window.AdMob.showAd( 
             true, // or false
             successCallback,
             failureCallback
         );

This plugin also allows you the option to listen for ad events.  The following
events are supported:

    document.addEventListener('onReceiveAd', callback);
    document.addEventListener('onFailedToReceiveAd', callback);
    document.addEventListener('onPresentScreen', callback);
    document.addEventListener('onDismissScreen', callback);
    document.addEventListener('onLeaveApplication', callback);
