cordova-plugin-admob
---------------------------
This is the AdMob Cordova Plugin for Android and iOS. It provides a way to request AdMob ads natively from JavaScript. 

This plugin was written and tested with the Google AdMob SDK version 6.4.0 for iOS, and Cordova 2.5.0.

Now, it's port to Cordova 3.0.0, and tested pass.

How to use?
---------------------------
To install this plugin, follow the [Command-line Interface Guide](http://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-line%20Interface).

It's recommended to use cordova command line tool: 

cordova plugin add https://github.com/floatinghotpot/cordova-plugin-admob.git

Check the README.md in sub folder for details.

Quick example
---------------------------
  if( window.plugins && window.plugins.AdMob ) {
    var am = window.plugins.AdMob;
    am.createBannerView( 
    {
    'publisherId': adId,
    'adSize': am.AD_SIZE.BANNER,
    'bannerAtTop': false
    }, 
    function() {
    	am.requestAd(
    		{ 'isTesting':isTesting }, 
    		function(){
    			am.showAd( true );
    		}, 
    		function(){ alert('failed to request ad'); }
    	);
    }, 
    function(){ alert('failed to create banner view'); }
    );
  } else {
    alert('AdMob plugin not available/ready.');
  }
