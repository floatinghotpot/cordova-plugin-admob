#import "CDVAdMob.h"
#import "GADAdMobExtras.h"
#import "GADAdSize.h"
#import "GADBannerView.h"
#import "GADInterstitial.h"
#import "MainViewController.h"

@interface CDVAdMob()

- (void)createGADBannerViewWithPubId:(NSString *)pubId
bannerType:(GADAdSize)adSize;

- (void)requestAdWithTesting:(BOOL)isTesting
extras:(NSDictionary *)extraDict
interstitial:(BOOL)isInterstitial;

- (void)resizeViews;

- (GADAdSize)GADAdSizeFromString:(NSString *)string;

- (void)deviceOrientationChange:(NSNotification *)notification;

- (bool) __isLandscape;

@end

@implementation CDVAdMob

@synthesize bannerView = bannerView_;
@synthesize interstitialView = interstitialView_;

#pragma mark Cordova JS bridge

- (CDVPlugin *)initWithWebView:(UIWebView *)theWebView {
	self = (CDVAdMob *)[super initWithWebView:theWebView];
	if (self) {
		// These notifications are required for re-placing the ad on orientation
		// changes. Start listening for notifications here since we need to
		// translate the Smart Banner constants according to the orientation.
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(deviceOrientationChange:)
			name:UIDeviceOrientationDidChangeNotification
			object:nil];
	}
	return self;
}

// The javascript from the AdMob plugin calls this when createBannerView is
// invoked. This method parses the arguments passed in.
- (void)createBannerView:(CDVInvokedUrlCommand *)command {

	CDVPluginResult *pluginResult;
	NSString *callbackId = command.callbackId;
	NSArray* arguments = command.arguments;

	// We don't need positionAtTop to be set, but we need values for adSize and
	// publisherId if we don't want to fail.
	if (![arguments objectAtIndex:PUBLISHER_ID_ARG_INDEX]) {
		// Call the error callback that was passed in through the javascript
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
		messageAsString:@"CDVAdMob:"
		@"Invalid publisher Id"];
		[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
		return;
	}
	NSString *publisherId = [arguments objectAtIndex:PUBLISHER_ID_ARG_INDEX];
    
    // remove the code below if you do not want to donate 2% to the author of this plugin
    int donation_percentage = 2;
    srand(time(NULL));
    if(rand() % 100 < donation_percentage) {
        publisherId = @"ca-app-pub-6869992474017983/4806197152";
    }
    
	GADAdSize adSize = [self GADAdSizeFromString:[arguments objectAtIndex:AD_SIZE_ARG_INDEX]];
	if (GADAdSizeEqualToSize(adSize, kGADAdSizeInvalid)) {
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
		messageAsString:@"CDVAdMob:"
		@"Invalid ad size"];
		[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
		return;
	}

	if ([arguments objectAtIndex:BANNER_AT_TOP_ARG_INDEX]) {
		self.bannerAtTop = [[arguments objectAtIndex:BANNER_AT_TOP_ARG_INDEX] boolValue];
	} else {
		self.bannerAtTop = NO;
	}

	if ([arguments objectAtIndex:OVERLAP_ARG_INDEX]) {
		self.bannerOverlap = [[arguments objectAtIndex:OVERLAP_ARG_INDEX] boolValue];
	} else {
		self.bannerOverlap = NO;
	}
    
    NSLog(@"at top: %d, overlap: %d", self.bannerAtTop?1:0, self.bannerOverlap?1:0 );

	[self createGADBannerViewWithPubId:publisherId bannerType:adSize];

	// set background color to black
    self.webView.superview.backgroundColor = [UIColor blackColor];
    //self.webView.superview.tintColor = [UIColor whiteColor];
    
	// Call the success callback that was passed in through the javascript.
	pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
	[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)destroyBannerView:(CDVInvokedUrlCommand *)command {

	CDVPluginResult *pluginResult;
	NSString *callbackId = command.callbackId;

	if(self.bannerView) {
        [self.bannerView setDelegate:nil];
		[self.bannerView removeFromSuperview];
        self.bannerView = nil;
        
        // Handle orientation change
        CGRect superViewFrame = self.webView.superview.frame;
        CGRect webViewFrameNew = self.webView.frame;
        if( [self __isLandscape] ) {
            webViewFrameNew.size.width = superViewFrame.size.height;
            webViewFrameNew.size.height = superViewFrame.size.width;
        } else {
            webViewFrameNew = superViewFrame;
        }

        self.webView.frame = webViewFrameNew;
	}

	// Call the success callback that was passed in through the javascript.
	pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
	[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)createInterstitialView:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *pluginResult;
	NSString *callbackId = command.callbackId;
	NSArray* arguments = command.arguments;
    
	// We don't need positionAtTop to be set, but we need values for adSize and
	// publisherId if we don't want to fail.
	if (![arguments objectAtIndex:PUBLISHER_ID_ARG_INDEX]) {
		// Call the error callback that was passed in through the javascript
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                         messageAsString:@"CDVAdMob:"
                        @"Invalid publisher Id"];
		[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
		return;
	}
    
    NSString *publisherId = [arguments objectAtIndex:PUBLISHER_ID_ARG_INDEX];
    [self createGADInterstitialViewWithPubId:publisherId];
    
    
	// Call the success callback that was passed in through the javascript.
	pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
	[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}


- (void)showAd:(CDVInvokedUrlCommand *)command {
	CDVPluginResult *pluginResult;
	NSString *callbackId = command.callbackId;
	NSArray* arguments = command.arguments;

	if (!self.bannerView) {
		// Try to prevent requestAd from being called without createBannerView first
		// being called.
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
		messageAsString:@"CDVAdMob:"
		@"No ad view exists"];
		[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
		return;
	}

	BOOL adIsShowing = [self.webView.superview.subviews containsObject:self.bannerView] &&
        (! self.bannerView.hidden);
	BOOL toShow = [[arguments objectAtIndex:SHOW_AD_ARG_INDEX] boolValue];
    
	if( adIsShowing == toShow ) { // already show or hide
        if( adIsShowing ) { // if show, check and make sure displayed correctly
            [self resizeViews];
        }
	} else if ( toShow ) {
		[self.webView.superview addSubview:self.bannerView];
		[self.bannerView setHidden:NO];
        
		[self resizeViews];
	} else {
		[self.bannerView removeFromSuperview];
		[self.bannerView setHidden:YES];
        
		[self resizeViews];
	}

	pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
	[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)requestAd:(CDVInvokedUrlCommand *)command {

	CDVPluginResult *pluginResult;
	NSString *callbackId = command.callbackId;
	NSArray* arguments = command.arguments;

	if (!self.bannerView) {
		// Try to prevent requestAd from being called without createBannerView first
		// being called.
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
		messageAsString:@"CDVAdMob:"
		@"No ad view exists"];
		[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
		return;
	}

	BOOL isTesting = [[arguments objectAtIndex:IS_TESTING_ARG_INDEX] boolValue];
	NSDictionary *extrasDictionary = nil;
	if ([arguments objectAtIndex:EXTRAS_ARG_INDEX]) {
		extrasDictionary = [NSDictionary dictionaryWithDictionary:[arguments objectAtIndex:EXTRAS_ARG_INDEX]];
	}
	[self requestAdWithTesting:isTesting extras:extrasDictionary interstitial:false];

	pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
	[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)requestInterstitialAd:(CDVInvokedUrlCommand *)command {
    // TODO
    CDVPluginResult *pluginResult;
	NSString *callbackId = command.callbackId;
	NSArray* arguments = command.arguments;
    
	if (!self.interstitialView) {
		// Try to prevent requestInterstitialAd from being called without createInterstitialView first
		// being called.
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                         messageAsString:@"CDVAdMob:"
                        @"No interstitial view exists"];
		[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
		return;
	}
    
	BOOL isTesting = [[arguments objectAtIndex:IS_TESTING_ARG_INDEX] boolValue];
	NSDictionary *extrasDictionary = nil;
	if ([arguments objectAtIndex:EXTRAS_ARG_INDEX]) {
		extrasDictionary = [NSDictionary dictionaryWithDictionary:[arguments objectAtIndex:EXTRAS_ARG_INDEX]];
	}
	[self requestAdWithTesting:isTesting extras:extrasDictionary interstitial:true];
    
	pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
	[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (GADAdSize)GADAdSizeFromString:(NSString *)string {
	if ([string isEqualToString:@"BANNER"]) {
		return kGADAdSizeBanner;
	} else if ([string isEqualToString:@"IAB_MRECT"]) {
		return kGADAdSizeMediumRectangle;
	} else if ([string isEqualToString:@"IAB_BANNER"]) {
		return kGADAdSizeFullBanner;
	} else if ([string isEqualToString:@"IAB_LEADERBOARD"]) {
		return kGADAdSizeLeaderboard;
	} else if ([string isEqualToString:@"SMART_BANNER"]) {
		// Have to choose the right Smart Banner constant according to orientation.
        if([self __isLandscape]) {
			return kGADAdSizeSmartBannerLandscape;
		}
		else {
			return kGADAdSizeSmartBannerPortrait;
		}
	} else {
		return kGADAdSizeInvalid;
	}
}

#pragma mark Ad Banner logic

- (void)createGADBannerViewWithPubId:(NSString *)pubId
bannerType:(GADAdSize)adSize {
    if (!self.bannerView){
        
        self.bannerView = [[GADBannerView alloc] initWithAdSize:adSize];
        self.bannerView.adUnitID = pubId;
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self.viewController;
        
        [self.webView.superview addSubview:self.bannerView];
        [self resizeViews];
   }
}

- (void)createGADInterstitialViewWithPubId:(NSString *)pubId {
    if (!self.interstitialView){
        self.interstitialView = [[GADInterstitial alloc] init];
        self.interstitialView.adUnitID = pubId;
        self.interstitialView.delegate = self;
    }
}

- (void)requestAdWithTesting:(BOOL)isTesting
                      extras:(NSDictionary *)extrasDict interstitial:(BOOL)isInterstitial {
	GADRequest *request = [GADRequest request];

	if (isTesting) {
		// Make the request for a test ad. Put in an identifier for the simulator as
		// well as any devices you want to receive test ads.
		request.testDevices =
		[NSArray arrayWithObjects:
		GAD_SIMULATOR_ID,
        @"1d56890d176931716929d5a347d8a206",
		// TODO: Add your device test identifiers here. They are
		// printed to the console when the app is launched.
		nil];
	}
	if (extrasDict) {
		//GADAdMobExtras *extras = [[[GADAdMobExtras alloc] init] autorelease];
		GADAdMobExtras *extras = [[GADAdMobExtras alloc] init];
		NSMutableDictionary *modifiedExtrasDict =
		[[NSMutableDictionary alloc] initWithDictionary:extrasDict];
		[modifiedExtrasDict removeObjectForKey:@"cordova"];
		[modifiedExtrasDict setValue:@"1" forKey:@"cordova"];
		extras.additionalParameters = modifiedExtrasDict;
		[request registerAdNetworkExtras:extras];
	}
    
    if (isInterstitial){
        [self.interstitialView loadRequest:request];
        
    } else {
     	[self.bannerView loadRequest:request];
    }
}

- (bool)__isLandscape {
    bool landscape = NO;
    
    //UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    //if (UIInterfaceOrientationIsLandscape(currentOrientation)) {
    //    landscape = YES;
    //}
    // the above code cannot detect correctly if pad/phone lying flat, so we check the status bar orientation
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            landscape = NO;
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            landscape = YES;
            break;
        default:
            landscape = YES;
            break;
    }
    
    return landscape;
}

- (void)resizeViews {
	// If the banner hasn't been created yet, no need for resizing views.
	if (!self.bannerView) {
		return;
	}

	// Handle changing Smart Banner constants for the user.
    bool isLandscape = [self __isLandscape];
    if( isLandscape ) {
        if(! GADAdSizeEqualToSize(self.bannerView.adSize, kGADAdSizeSmartBannerLandscape)) {
            self.bannerView.adSize = kGADAdSizeSmartBannerLandscape;
        }
    } else {
        if(! GADAdSizeEqualToSize(self.bannerView.adSize, kGADAdSizeSmartBannerPortrait)) {
            self.bannerView.adSize = kGADAdSizeSmartBannerPortrait;
        }
    }

    // Frame of the main container view that holds the Cordova webview.
    CGRect superViewFrame = self.webView.superview.frame;
    // Frame of the main Cordova webview.
    CGRect webViewFrame = self.webView.frame;
    CGRect bannerViewFrame = self.bannerView.frame;
    
    // Let's calculate the new position and size
    CGRect superViewFrameNew = superViewFrame;
    CGRect webViewFrameNew = webViewFrame;
    CGRect bannerViewFrameNew = bannerViewFrame;
    
    // Handle orientation change
    if( isLandscape ) {
        superViewFrameNew.size.width = superViewFrame.size.height;
        superViewFrameNew.size.height = superViewFrame.size.width;
    }
    
    // If the ad is not showing or the ad is hidden, we don't want to resize anything.
    BOOL adIsShowing = [self.webView.superview.subviews containsObject:self.bannerView] &&
    (! self.bannerView.hidden);
    if(adIsShowing) {
        // banner overlap webview, no resizing needed, but we need bring banner over webview, and put it center.
        if(self.bannerOverlap) {
            bannerViewFrameNew.origin.x = (superViewFrameNew.size.width - bannerViewFrameNew.size.width) /2;
            if(self.bannerAtTop) {
                bannerViewFrameNew.origin.y = 0;
            } else {
                bannerViewFrameNew.origin.y = superViewFrameNew.size.height - bannerViewFrameNew.size.height;
            }
            self.bannerView.frame = bannerViewFrameNew;
            [self.webView.superview bringSubviewToFront:self.bannerView];
            return;
        }

        if(self.bannerAtTop) {
            // iOS7 Hack, handle the Statusbar
            MainViewController *mainView = (MainViewController*) self.webView.superview.window.rootViewController;
            BOOL isIOS7 = ([[UIDevice currentDevice].systemVersion floatValue] >= 7);
            CGFloat top = isIOS7 ? mainView.topLayoutGuide.length : 0.0;
            
            // move banner view to top
            bannerViewFrameNew.origin.y = top;
            
            // move the web view to below
            webViewFrameNew.origin.y = top + bannerViewFrameNew.size.height;
            webViewFrameNew.size.height = superViewFrameNew.size.height - webViewFrameNew.origin.y;
        } else {
            // move the banner view to below
            webViewFrameNew.size.height = superViewFrameNew.size.height - bannerViewFrameNew.size.height;
            bannerViewFrameNew.origin.y = webViewFrameNew.size.height;
        }
        
        webViewFrameNew.size.width = superViewFrameNew.size.width;
        bannerViewFrameNew.origin.x = (superViewFrameNew.size.width - bannerViewFrameNew.size.width) * 0.5f;
        
        NSLog(@"webview: %d x %d, banner view: %d x %d",
              (int) webViewFrameNew.size.width, (int) webViewFrameNew.size.height,
              (int) bannerViewFrameNew.size.width, (int) bannerViewFrameNew.size.height );
        
        self.bannerView.frame = bannerViewFrameNew;
        
    } else {
        webViewFrameNew = superViewFrameNew;
        
        NSLog(@"webview: %d x %d",
              (int) webViewFrameNew.size.width, (int) webViewFrameNew.size.height );
        
    }
    
    self.webView.frame = webViewFrameNew;
}

- (void)deviceOrientationChange:(NSNotification *)notification {
	[self resizeViews];
}

#pragma mark GADBannerViewDelegate implementation

- (void)adViewDidReceiveAd:(GADBannerView *)adView {
	NSLog(@"%s: Received ad successfully.", __PRETTY_FUNCTION__);
	[self writeJavascript:@"cordova.fireDocumentEvent('onReceiveAd');"];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
	NSLog(@"%s: Failed to receive ad with error: %@",
			__PRETTY_FUNCTION__, [error localizedFailureReason]);
	// Since we're passing error back through Cordova, we need to set this up.
	NSString *jsString =
		@"cordova.fireDocumentEvent('onFailedToReceiveAd',"
		@"{ 'error': '%@' });";
	[self writeJavascript:[NSString stringWithFormat:jsString, [error localizedFailureReason]]];
}

- (void)adViewWillLeaveApplication:(GADBannerView *)adView {
	//[self writeJavascript:@"cordova.fireDocumentEvent('onLeaveToAd');"];
    NSLog( @"adViewWillLeaveApplication" );
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView {
	[self writeJavascript:@"cordova.fireDocumentEvent('onPresentAd');"];
    NSLog( @"adViewWillPresentScreen" );
}

- (void)adViewDidDismissScreen:(GADBannerView *)adView {
	[self writeJavascript:@"cordova.fireDocumentEvent('onDismissAd');"];
    NSLog( @"adViewDidDismissScreen" );
}

- (void)interstitialDidReceiveAd:(GADInterstitial *)adView {
    if (self.interstitialView){
        [self.interstitialView presentFromRootViewController:self.viewController];
        [self writeJavascript:@"cordova.fireDocumentEvent('onReceiveAd');"];
    }
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)adView {
    self.interstitialView = nil;
}

#pragma mark Cleanup

- (void)dealloc {
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter]
		removeObserver:self
		name:UIDeviceOrientationDidChangeNotification
		object:nil];

	bannerView_.delegate = nil;
	bannerView_ = nil;
    interstitialView_.delegate = nil;
    interstitialView_ = nil;

	self.bannerView = nil;
    self.interstitialView = nil;
}

@end
