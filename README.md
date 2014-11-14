# cordova-plugin-admob #

AdMob Cordova Plugin, provides a way to request AdMob ads natively from JavaScript. 

## Platform SDK supported ##

* Android, using Google Play Service for Android, r19
* iOS, using AdMob SDK for iOS, v6.12.0
* Windows Phone, using AdMob SDK for Windows Phone 8, v6.5.13

## How to use? ##
To install this plugin, follow the [Command-line Interface Guide](http://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-line%20Interface).

    cordova plugin add https://github.com/floatinghotpot/cordova-plugin-admob.git
    
Or,

    cordova plugin add com.rjfun.cordova.plugin.admob

Note: ensure you have a proper AdMob account and create an Id for your app.

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

## Example code ##

Check the [test/index.html] (https://github.com/floatinghotpot/cordova-plugin-admob/blob/master/test/index.html).

See the working example code in [demo under test folder](test/index.html), and here are some screenshots.
 
## Screenshots (banner Ad / interstitial Ad) ##

iPhone:

![ScreenShot](demo/admob-iphone.jpg)

## Credits ##

This plugin is mainly maintained by Raymond Xie, and also thanks to following contributors:

* @jumin-zhu, added interstitial support for Android.
* @fersingb, added interstitial support for iOS.
* @AlexB71, improved WP8 support.
* @ihshim523, added initial WP8 support.
* And, bugfix patches from @chrisschaub, @jmelvin, @mbektchiev, @grahamkennery, @bastaware, @EddyVerbruggen, @codebykevin, @codebykevin, @zahhak.

You can use this plugin for FREE. To support the project, donation is welcome.

* Donate via PayPal to rjfun.mobile@gmail.com
* Keep the 2% Ad traffic sharing code.

Forking and improving is welcome. Please ADD VALUE, instead of changing the name only.

## See Also ##

More enhanced Cordova/PhoneGap plugins for the world leading Mobile Ad services:

* [AdMob Plugin Pro](https://github.com/floatinghotpot/cordova-admob-pro), enhanced Google AdMob plugin, easy API, with mediation to multiple Ad networks.
* [mMedia Plugin Pro](https://github.com/floatinghotpot/cordova-plugin-mmedia), for Millennial Media Ad service, support impressive video Ad.
* [iAd Plugin](https://github.com/floatinghotpot/cordova-plugin-iad), Apple iAd service. 
* [FacebookAds Plugin](https://github.com/floatinghotpot/cordova-plugin-facebookads), for Facebook Audience Network Ads service.
* [FlurryAds Plugin](https://github.com/floatinghotpot/cordova-plugin-flurry), for Yahoo Flurry Ads service.
* [MoPub Plugin Pro](https://github.com/floatinghotpot/cordova-plugin-mopub), for MobPub Ads service.
* [MobFox Plugin Pro](https://github.com/floatinghotpot/cordova-mobfox-pro), for MobFox Ads service, support video Ad and many other Ad network with server-side integration.

### [AdMob PluginPro](https://github.com/floatinghotpot/cordova-admob-pro) is more recommended. ###

N-in-1 Advert Plugin for Cordova/PhoneGap. Maximize revenue with mediation to AdMob, DoubleClick, iAd, Flurry, Millennial Media, InMobi, Mobfox, and much more.

Highlights:
- [x] Easy-to-use: Can display Ad with single line of Js code.
- [x] Powerful: Support banner, interstitial, and video Ad.
- [x] Max revenue: Support mediation with up to 8 leading mobile Ad services.
- [x] Multi-size: Multiple banner size, also support custom size.
- [x] Flexible: Fixed and overlapped mode, put banner at any position with overlap mode.
- [x] Smart: Auto fit on orientation change.
- [x] Up to date: Latest SDK and Android Google play services.
- [x] Good support: Actively maintained, prompt response.

Tested with:
* [x] Cordova CLI, v3.0+ (do not use the buggy v3.4)
* [x] Intel XDK, r1095+
* [x] IBM Worklight, v6.2+

Mediation with:
* [x] AdMob
* [x] DFP (DoubleClick for Publisher)
* [x] Facebook Audience Network
* [x] Flurry
* [x] iAd
* [x] InMobi
* [x] Millennial Media
* [x] MobFox

News:
- Recommended by Telerik in Verified Plugins Marketplace. [read more ...](http://plugins.telerik.com/plugin/admob)
- Recommended by William SerGio in code project (20 Jun 2014), [read more ...](http://www.codeproject.com/Articles/788304/AdMob-Plugin-for-Latest-Version-of-PhoneGap-Cordov)
- Recommended by Arne in Scirra Game Dev Forum (07 Aug, 2014), [read more ...](https://www.scirra.com/forum/plugin-admob-ads-for-crosswalk_t111940)
- Recommended by Intel XDK team (08/22/2014), [read more ...](https://software.intel.com/en-us/html5/articles/adding-google-play-services-to-your-cordova-application)

More plugins by Raymond Xie, [click here](http://floatinghotpot.github.io/).

Project outsourcing and consulting service is also available. Please [contact us](http://floatinghotpot.github.io) if you have the business needs.

