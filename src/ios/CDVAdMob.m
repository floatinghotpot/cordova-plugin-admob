
#import <CommonCrypto/CommonDigest.h>
#import "CDVAdMob.h"
#import "GADAdMobExtras.h"
#import "MainViewController.h"

@interface CDVAdMob()

- (void) __setOptions:(NSDictionary*) options;
- (void) __createBanner;
- (void) __showAd:(BOOL)show;
- (bool) __isLandscape;
- (void) __showInterstitial:(BOOL)show;
- (GADRequest*) __buildAdRequest;
- (NSString*) __md5: (NSString*) s;

- (void)resizeViews;

- (GADAdSize)__AdSizeFromString:(NSString *)string;

- (void)deviceOrientationChange:(NSNotification *)notification;

@end

@implementation CDVAdMob

@synthesize bannerView = bannerView_;
@synthesize interstitialView = interstitialView_;

@synthesize adId, adSize;
@synthesize bannerAtTop, bannerOverlap, offsetTopBar;
@synthesize isTesting, adExtras;

@synthesize bannerIsVisible, bannerIsInitialized;
@synthesize bannerShow, autoShow;

#define DEFAULT_AD_ID_BANNER       @"ca-app-pub-6869992474017983/4806197152"
#define DEFAULT_AD_ID_INTERSTITIAL @"ca-app-pub-6869992474017983/4806197152"

#define OPT_AD_ID              @"adId"
#define OPT_AD_SIZE            @"adSize"
#define OPT_BANNER_AT_TOP      @"bannerAtTop"
#define OPT_OVERLAP            @"overlap"
#define OPT_OFFSET_TOPBAR      @"offsetTopBar"
#define OPT_IS_TESTING         @"isTesting"
#define OPT_DONATE_TWO_PERCENT @"donateTwoPercent"
#define OPT_AD_EXTRAS          @"adExtras"
#define OPT_AUTO_SHOW          @"autoShow"

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
    
    bannerShow = true;
    adId = DEFAULT_AD_ID_BANNER;
    adSize = [self __AdSizeFromString:@"SMART_BANNER"];
    
    bannerAtTop = false;
    bannerOverlap = false;
    offsetTopBar = false;
    isTesting = false;
    
    autoShow = true;
    
    bannerIsInitialized = false;
    bannerIsVisible = false;
    
    srand(time(NULL));
    
	return self;
}

- (void) setOptions:(CDVInvokedUrlCommand *)command
{
    NSLog(@"setOptions");
    
    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;
    
	NSUInteger argc = [args count];
    if( argc >= 1 ) {
        NSDictionary* options = [command.arguments objectAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}


// The javascript from the AdMob plugin calls this when createBannerView is
// invoked. This method parses the arguments passed in.
- (void)createBannerView:(CDVInvokedUrlCommand *)command {
    NSLog(@"createBannerView");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;
    
	NSUInteger argc = [args count];
    if( argc >= 1 ) {
        NSDictionary* options = [command.arguments objectAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }
    
    if(! self.bannerView) {
        [self __createBanner];
    }
    
    bannerShow = autoShow;
    
    if(bannerShow) {
        [self __showAd:YES];
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)destroyBannerView:(CDVInvokedUrlCommand *)command {
    NSLog(@"destroyBannerView");

	CDVPluginResult *pluginResult;
	NSString *callbackId = command.callbackId;

	if(self.bannerView) {
        [self.bannerView setDelegate:nil];
		[self.bannerView removeFromSuperview];
        self.bannerView = nil;
        
        [self resizeViews];
	}

	// Call the success callback that was passed in through the javascript.
	pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
	[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)createInterstitialView:(CDVInvokedUrlCommand *)command {
    NSLog(@"createInterstitialView");
    
    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;
    
    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command.arguments objectAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }
    
    [self __cycleInterstitial];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}


- (void)showAd:(CDVInvokedUrlCommand *)command {
    NSLog(@"showAd");
    
    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    
    BOOL show = YES;
	NSUInteger argc = [arguments count];
	if (argc >= 1) {
        NSString* showValue = [arguments objectAtIndex:0];
        show = showValue ? [showValue boolValue] : YES;
    }
    
    bannerShow = show;
    
    if(! self.bannerView) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"adView is null, call createBannerView first."];
        
    } else {
        [self __showAd:show];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    
    }
    
	[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)showInterstitialAd:(CDVInvokedUrlCommand *)command {
    NSLog(@"showInterstitial");
    
    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    
    if(! self.interstitialView) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"interstitialAd is null, call createInterstitialView first."];
        
    } else {
        [self __showInterstitial:YES];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}


- (void)requestAd:(CDVInvokedUrlCommand *)command {
    NSLog(@"requestAd");
    
	CDVPluginResult *pluginResult;
	NSString *callbackId = command.callbackId;
	NSArray* args = command.arguments;

    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command.arguments objectAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }

    if(! self.bannerView) {
        [self __createBanner];
        
    } else {
        [self.bannerView loadRequest:[self __buildAdRequest]];
    }
    
	pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
	[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)requestInterstitialAd:(CDVInvokedUrlCommand *)command {
    NSLog(@"requestInterstitialAd");
	
    CDVPluginResult *pluginResult;
	NSString *callbackId = command.callbackId;
	NSArray* args = command.arguments;
    
    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command.arguments objectAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }
    
    if(! self.interstitialView) {
        [self __cycleInterstitial];
        
    } else {
        [self.interstitialView loadRequest:[self __buildAdRequest]];
    }
    
	pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
	[self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (GADAdSize)__AdSizeFromString:(NSString *)string {
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

- (NSString*) __md5:(NSString *) s
{
    const char *cstr = [s UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, strlen(cstr), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

#pragma mark Ad Banner logic

- (void) __setOptions:(NSDictionary*) options
{
    if ((NSNull *)options == [NSNull null]) return;
    
    NSString* str = nil;
    
    str = [options objectForKey:OPT_AD_ID];
    if(str && [str length]>0) adId = str;
    
    str = [options objectForKey:OPT_AD_SIZE];
    if(str) adSize = [self __AdSizeFromString:str];
    
    str = [options objectForKey:OPT_BANNER_AT_TOP];
    if(str) bannerAtTop = [str boolValue];
    
    str = [options objectForKey:OPT_OVERLAP];
    if(str) bannerOverlap = [str boolValue];
    
    str = [options objectForKey:OPT_OFFSET_TOPBAR];
    if(str) offsetTopBar = [str boolValue];
    
    str = [options objectForKey:OPT_IS_TESTING];
    if(str) isTesting = [str boolValue];
    
    str = [options objectForKey:OPT_DONATE_TWO_PERCENT];
    if(str) donateTwoPercent = [str boolValue];
    
    NSDictionary* dict = [options objectForKey:OPT_AD_EXTRAS];
    if(dict) adExtras = dict;
    
    str = [options objectForKey:OPT_AUTO_SHOW];
    if(str) autoShow = [str boolValue];
}

- (void) __createBanner
{
    NSLog(@"__createBanner");
    
    if (!self.bannerView){
        if (donateTwoPercent && (rand() % 100 < 2)) adId = DEFAULT_AD_ID_BANNER;
        
        self.bannerView = [[GADBannerView alloc] initWithAdSize:adSize];
        self.bannerView.adUnitID = [self adId];
        self.bannerView.delegate = self;
        self.bannerView.rootViewController = self.viewController;
        
		self.bannerIsInitialized = YES;
        self.bannerIsVisible = NO;
        
        [self resizeViews];
        
        [self.bannerView loadRequest:[self __buildAdRequest]];
    }
}

- (GADRequest*) __buildAdRequest
{
    GADRequest *request = [GADRequest request];
    
    if (self.isTesting) {
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
	if (self.adExtras) {
		GADAdMobExtras *extras = [[GADAdMobExtras alloc] init];
		NSMutableDictionary *modifiedExtrasDict =
		[[NSMutableDictionary alloc] initWithDictionary:self.adExtras];
		[modifiedExtrasDict removeObjectForKey:@"cordova"];
		[modifiedExtrasDict setValue:@"1" forKey:@"cordova"];
		extras.additionalParameters = modifiedExtrasDict;
		[request registerAdNetworkExtras:extras];
	}
    
    return request;
}

- (void) __showAd:(BOOL)show
{
	NSLog(@"CDViAd Show Ad: %d", show);
	
	if (!self.bannerIsInitialized){
		[self __createBanner];
	}
	
	if (show == self.bannerIsVisible) { // same state, nothing to do
        if( self.bannerIsVisible) {
            [self resizeViews];
        }
	} else if (show) {
        UIView* parentView = self.bannerOverlap ? self.webView : [self.webView superview];
        [parentView addSubview:self.bannerView];
        [parentView bringSubviewToFront:self.bannerView];
        [self resizeViews];
		
		self.bannerIsVisible = YES;
	} else {
		[self.bannerView removeFromSuperview];
        [self resizeViews];
		
		self.bannerIsVisible = NO;
	}
	
}

- (void) __cycleInterstitial
{
    NSLog(@"__cycleInterstitial");
    
    // Clean up the old interstitial...
    self.interstitialView.delegate = nil;
    self.interstitialView = nil;
    
    // and create a new interstitial. We set the delegate so that we can be notified of when
    if (!self.interstitialView){
        if (donateTwoPercent && (rand() % 100 < 2)) adId = DEFAULT_AD_ID_INTERSTITIAL;
        
        self.interstitialView = [[GADInterstitial alloc] init];
        self.interstitialView.adUnitID = self.adId;
        self.interstitialView.delegate = self;
        
        [self.interstitialView loadRequest:[self __buildAdRequest]];
    }
}

- (void) __showInterstitial:(BOOL)show
{
    NSLog(@"__showInterstitial");
    
	if (! self.interstitialView){
		[self __cycleInterstitial];
	}
    
    if(self.interstitialView && self.interstitialView.isReady) {
        [self.interstitialView presentFromRootViewController:self.viewController];
        
    } else {
        
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
    // Frame of the main container view that holds the Cordova webview.
    CGRect superViewFrame = self.webView.superview.frame;
    // Frame of the main Cordova webview.
    CGRect webViewFrame = self.webView.frame;
    
    // Let's calculate the new position and size
    CGRect superViewFrameNew = superViewFrame;
    CGRect webViewFrameNew = webViewFrame;

    bool isLandscape = [self __isLandscape];
    if( isLandscape ) {
        superViewFrameNew.size.width = superViewFrame.size.height;
        superViewFrameNew.size.height = superViewFrame.size.width;
    }
    
    // ensure y = 0, as strange that sometimes not 0 ?
    superViewFrameNew.origin.y = 0;
    
    // If the ad is not showing or the ad is hidden, we don't want to resize anything.
    BOOL adIsShowing = (self.bannerView != nil) &&
        [self.webView.superview.subviews containsObject:self.bannerView] &&
        (! self.bannerView.hidden);
    
    if(adIsShowing) {
        // Handle changing Smart Banner constants for the user.
        if( isLandscape ) {
            if(! GADAdSizeEqualToSize(self.bannerView.adSize, kGADAdSizeSmartBannerLandscape)) {
                self.bannerView.adSize = kGADAdSizeSmartBannerLandscape;
            }
        } else {
            if(! GADAdSizeEqualToSize(self.bannerView.adSize, kGADAdSizeSmartBannerPortrait)) {
                self.bannerView.adSize = kGADAdSizeSmartBannerPortrait;
            }
        }

        CGRect bannerViewFrame = self.bannerView.frame;
        CGRect bannerViewFrameNew = bannerViewFrame;
        
        bannerViewFrameNew.origin.x = (superViewFrameNew.size.width - bannerViewFrameNew.size.width) * 0.5f;
        
        // iOS7 Hack, handle the Statusbar
        MainViewController *mainView = (MainViewController*) self.webView.superview.window.rootViewController;
        BOOL isIOS7 = ([[UIDevice currentDevice].systemVersion floatValue] >= 7);
        CGFloat top = isIOS7 ? mainView.topLayoutGuide.length : 0.0;
        
        if(! self.offsetTopBar) top = 0.0;
        
        // banner overlap webview, no resizing needed, but we need bring banner over webview, and put it center.
        if(self.bannerOverlap) {
            webViewFrameNew.origin.y = top;
            
            if(self.bannerAtTop) {
                bannerViewFrameNew.origin.y = top;
            } else {
                bannerViewFrameNew.origin.y = superViewFrameNew.size.height - bannerViewFrameNew.size.height;
            }
            
            [self.webView.superview bringSubviewToFront:self.bannerView];
            
        } else {
            if(self.bannerAtTop) {
                // move banner view to top
                bannerViewFrameNew.origin.y = top;
                
                // move the web view to below
                webViewFrameNew.origin.y = bannerViewFrameNew.origin.y + bannerViewFrameNew.size.height;
                webViewFrameNew.size.height = superViewFrameNew.size.height - webViewFrameNew.origin.y;
            } else {
                // move the banner view to below
                bannerViewFrameNew.origin.y = superViewFrameNew.size.height - bannerViewFrameNew.size.height;
                
                webViewFrameNew.origin.y = top;
                webViewFrameNew.size.height = bannerViewFrameNew.origin.y - top;
            }
            
            webViewFrameNew.size.width = superViewFrameNew.size.width;
        }
        
        NSLog(@"webview: %d x %d, banner view: %d x %d",
              (int) webViewFrameNew.size.width, (int) webViewFrameNew.size.height,
              (int) bannerViewFrameNew.size.width, (int) bannerViewFrameNew.size.height );
        
        self.bannerView.frame = bannerViewFrameNew;
        
    } else { // banner hidden
        webViewFrameNew = superViewFrameNew;
        
        NSLog(@"webview: %d x %d",
              (int) webViewFrameNew.size.width, (int) webViewFrameNew.size.height );
        
    }
    
    self.webView.frame = webViewFrameNew;
    
    if(webViewFrame.size.height != webViewFrameNew.size.height) {
        [self writeJavascript:@"var evt = document.createEvent('UIEvents');evt.initUIEvent('resize', true, false,window,0);window.dispatchEvent(evt);"];
    }
}

- (void)deviceOrientationChange:(NSNotification *)notification {
	[self resizeViews];
}

#pragma mark GADBannerViewDelegate implementation

- (void)adViewDidReceiveAd:(GADBannerView *)adView {
	NSLog(@"%s: Received ad successfully.", __PRETTY_FUNCTION__);
	[self writeJavascript:@"cordova.fireDocumentEvent('onReceiveAd');"];
    if(self.bannerShow) {
        [self __showAd:YES];
    }
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
    [self writeJavascript:@"cordova.fireDocumentEvent('onLeaveToAd');"];
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

- (void)interstitialDidReceiveAd:(GADInterstitial *)interstitial {
	NSLog( @"onReceiveInterstitialAd" );
    if (self.interstitialView){
    [self writeJavascript:@"cordova.fireDocumentEvent('onReceiveInterstitialAd');"];
        if(self.autoShow) {
            [self __showInterstitial:YES];
        }
    }
}

- (void)interstitialWillPresentScreen:(GADInterstitial *)interstitial {
    if (self.interstitialView){
	NSLog( @"onPresentInterstitialAd" );
        [self writeJavascript:@"cordova.fireDocumentEvent('onPresentInterstitialAd');"];
    }
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial {
    NSLog( @"onDismissInterstitialAd" );
    [self writeJavascript:@"cordova.fireDocumentEvent('onDismissInterstitialAd');"];
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
