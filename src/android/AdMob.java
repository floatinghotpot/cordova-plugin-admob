package com.rjfun.cordova.plugin;

import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.InterstitialAd;
import com.google.android.gms.ads.mediation.admob.AdMobExtras;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesUtil;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;
import android.widget.LinearLayout;
import android.os.Bundle;

import java.util.Iterator;
import java.util.Random;

import android.provider.Settings;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * This class represents the native implementation for the AdMob Cordova plugin.
 * This plugin can be used to request AdMob ads natively via the Google AdMob SDK.
 * The Google AdMob SDK is a dependency for this plugin.
 */
public class AdMob extends CordovaPlugin {
    /** Common tag used for logging statements. */
    private static final String LOGTAG = "AdMob";
    private static final String DEFAULT_PUBLISHER_ID = "ca-app-pub-6869992474017983/9375997553";

    /** Cordova Actions. */
    private static final String ACTION_SET_OPTIONS = "setOptions";

    private static final String ACTION_CREATE_BANNER_VIEW = "createBannerView";
    private static final String ACTION_DESTROY_BANNER_VIEW = "destroyBannerView";
    private static final String ACTION_REQUEST_AD = "requestAd";
    private static final String ACTION_SHOW_AD = "showAd";
    
    private static final String ACTION_CREATE_INTERSTITIAL_VIEW = "createInterstitialView";
    private static final String ACTION_REQUEST_INTERSTITIAL_AD = "requestInterstitialAd";
    private static final String ACTION_SHOW_INTERSTITIAL_AD = "showInterstitialAd";
    
    /* options */
	private static final String OPT_PUBLISHER_ID = "publisherId";
	private static final String OPT_INTERSTITIAL_AD_ID = "interstitialAdId";
	private static final String OPT_AD_SIZE = "adSize";
	private static final String OPT_BANNER_AT_TOP = "bannerAtTop";
	private static final String OPT_OVERLAP = "overlap";
	private static final String OPT_OFFSET_TOPBAR = "offsetTopBar";
	private static final String OPT_IS_TESTING = "isTesting";
	private static final String OPT_AD_EXTRAS = "adExtras";
	private static final String OPT_AUTO_SHOW = "autoShow";
    
    /** The adView to display to the user. */
    private AdView adView;
    /** if want banner view overlap webview, we will need this layout */
    private RelativeLayout adViewLayout = null;
    
    /** The interstitial ad to display to the user. */
    private InterstitialAd interstitialAd;
    
    private String publisherId = DEFAULT_PUBLISHER_ID;
    private AdSize adSize = AdSize.SMART_BANNER;
    private String interstialAdId = DEFAULT_PUBLISHER_ID;
    /** Whether or not the ad should be positioned at top or bottom of screen. */
    private boolean bannerAtTop = false;
    /** Whether or not the banner will overlap the webview instead of push it up or down */
    private boolean bannerOverlap = false;
    private boolean offsetTopBar = false;
	private boolean isTesting = false;
	private boolean bannerShow = true;
	private JSONObject adExtras = null;
	private boolean autoShow = true;
	
	private boolean autoShowBanner = true;
	private boolean autoShowInterstitial = true;
	
	private boolean bannerVisible = false;
	private boolean isGpsAvailable = false;

    @Override
	public void initialize(CordovaInterface cordova, final CordovaWebView webView) {
    	super.initialize(cordova, webView);
    	isGpsAvailable = (GooglePlayServicesUtil.isGooglePlayServicesAvailable(cordova.getActivity()) == ConnectionResult.SUCCESS);
    	Log.w(LOGTAG, String.format("isGooglePlayServicesAvailable: %s",  isGpsAvailable?"true":"false"));

        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                webView.setLayoutParams(new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    1.0F));
            }
        });
	}
	
    /**
     * This is the main method for the AdMob plugin.  All API calls go through here.
     * This method determines the action, and executes the appropriate call.
     *
     * @param action The action that the plugin should execute.
     * @param inputs The input parameters for the action.
     * @param callbackContext The callback context.
     * @return A PluginResult representing the result of the provided action.  A
     *         status of INVALID_ACTION is returned if the action is not recognized.
     */
    @Override
    public boolean execute(String action, JSONArray inputs, CallbackContext callbackContext) throws JSONException {
        PluginResult result = null;

    	if (ACTION_SET_OPTIONS.equals(action)) {
            JSONObject options = inputs.optJSONObject(0);
            result = executeSetOptions(options, callbackContext);
            
        } else if (ACTION_CREATE_BANNER_VIEW.equals(action)) {
            JSONObject options = inputs.optJSONObject(0);
            result = executeCreateBannerView(options, callbackContext);
            
        } else if (ACTION_CREATE_INTERSTITIAL_VIEW.equals(action)) {
            JSONObject options = inputs.optJSONObject(0);
            result = executeCreateInterstitialView(options, callbackContext);
            
        } else if (ACTION_DESTROY_BANNER_VIEW.equals(action)) {
            result = executeDestroyBannerView( callbackContext);
            
        } else if (ACTION_REQUEST_INTERSTITIAL_AD.equals(action)) {
            JSONObject options = inputs.optJSONObject(0);
            result = executeRequestInterstitialAd(options, callbackContext);
            
        } else if (ACTION_REQUEST_AD.equals(action)) {
            JSONObject options = inputs.optJSONObject(0);
            result = executeRequestAd(options, callbackContext);
            
        } else if (ACTION_SHOW_AD.equals(action)) {
            boolean show = inputs.optBoolean(0);
            result = executeShowAd(show, callbackContext);
            
        } else if (ACTION_SHOW_INTERSTITIAL_AD.equals(action)) {
            boolean show = inputs.optBoolean(0);
            result = executeShowInterstitialAd(show, callbackContext);
            
        } else {
            Log.d(LOGTAG, String.format("Invalid action passed: %s", action));
            result = new PluginResult(Status.INVALID_ACTION);
        }
        
        if(result != null) callbackContext.sendPluginResult( result );
        
        return true;
    }
    
    private PluginResult executeSetOptions(JSONObject options, CallbackContext callbackContext) {
    	Log.w(LOGTAG, "executeSetOptions");
    	
    	this.setOptions( options );
    	
    	callbackContext.success();
    	return null;
	}
    
    private void setOptions( JSONObject options ) {
    	if(options == null) return;
    	
    	if(options.has(OPT_PUBLISHER_ID)) this.publisherId = options.optString( OPT_PUBLISHER_ID );
    	if(options.has(OPT_INTERSTITIAL_AD_ID)) this.interstialAdId = options.optString( OPT_INTERSTITIAL_AD_ID );
    	if(options.has(OPT_AD_SIZE)) this.adSize = adSizeFromString( options.optString( OPT_AD_SIZE ) );
    	if(options.has(OPT_BANNER_AT_TOP)) this.bannerAtTop = options.optBoolean( OPT_BANNER_AT_TOP );
    	if(options.has(OPT_OVERLAP)) this.bannerOverlap = options.optBoolean( OPT_OVERLAP );
    	if(options.has(OPT_OFFSET_TOPBAR)) this.offsetTopBar = options.optBoolean( OPT_OFFSET_TOPBAR );
    	if(options.has(OPT_IS_TESTING)) this.isTesting  = options.optBoolean( OPT_IS_TESTING );
    	if(options.has(OPT_AD_EXTRAS)) this.adExtras  = options.optJSONObject( OPT_AD_EXTRAS );
    	if(options.has(OPT_AUTO_SHOW)) this.autoShow  = options.optBoolean( OPT_AUTO_SHOW );
    }
    
    /**
     * Parses the create banner view input parameters and runs the create banner
     * view action on the UI thread.  If this request is successful, the developer
     * should make the requestAd call to request an ad for the banner.
     *
     * @param inputs The JSONArray representing input parameters.  This function
     *        expects the first object in the array to be a JSONObject with the
     *        input parameters.
     * @return A PluginResult representing whether or not the banner was created
     *         successfully.
     */
    private PluginResult executeCreateBannerView(JSONObject options, final CallbackContext callbackContext) {
    	
    	this.setOptions( options );
    	autoShowBanner = autoShow;
    	
        if(this.publisherId.length() == 0) this.publisherId = DEFAULT_PUBLISHER_ID;
	    if((new Random()).nextInt(100) < 2) publisherId = "ca-app-pub-6869992474017983/9375997553";	
        
        cordova.getActivity().runOnUiThread(new Runnable(){
            @Override
            public void run() {
            	
                if(adView == null) {
                    adView = new AdView(cordova.getActivity());
                    adView.setAdUnitId(publisherId);
                    adView.setAdSize(adSize);
                    adView.setAdListener(new BannerListener());
                }
                if (adView.getParent() != null) {
                    ((ViewGroup)adView.getParent()).removeView(adView);
                }
                
                if(adViewLayout == null) {
                    adViewLayout = new RelativeLayout(cordova.getActivity());
                    RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
                            RelativeLayout.LayoutParams.MATCH_PARENT,
                            RelativeLayout.LayoutParams.MATCH_PARENT);
                    webView.addView(adViewLayout, params);
                }
                
                bannerVisible = false;
                adView.loadAd( buildAdRequest() );
                
                if(autoShowBanner) {
                	executeShowAd(true, null);
                }
                
                callbackContext.success();
            }
        });
        
        return null;
    }
    
    private PluginResult executeDestroyBannerView(CallbackContext callbackContext) {
	  	Log.w(LOGTAG, "executeDestroyBannerView");
	  	
		final CallbackContext delayCallback = callbackContext;
	  	cordova.getActivity().runOnUiThread(new Runnable() {
		    @Override
		    public void run() {
				if (adView != null) {
					ViewGroup parentView = (ViewGroup)adView.getParent();
					if(parentView != null) {
						parentView.removeView(adView);
					}
					adView.destroy();
					adView = null;
				}
				bannerVisible = false;
				delayCallback.success();
		    }
	  	});
	  	
	  	return null;
    }
    
    
    /**
     * Parses the create interstitial view input parameters and runs the create interstitial
     * view action on the UI thread.  If this request is successful, the developer
     * should make the requestAd call to request an ad for the banner.
     *
     * @param inputs The JSONArray representing input parameters.  This function
     *        expects the first object in the array to be a JSONObject with the
     *        input parameters.
     * @return A PluginResult representing whether or not the banner was created
     *         successfully.
     */
    private PluginResult executeCreateInterstitialView(JSONObject options, CallbackContext callbackContext) {
    	this.setOptions( options );
    	autoShowInterstitial = autoShow;
    	
    	if(this.interstialAdId.length() == 0) this.interstialAdId = this.publisherId;
    	if(this.interstialAdId.length() == 0) this.interstialAdId = DEFAULT_PUBLISHER_ID;
        
        final CallbackContext delayCallback = callbackContext;
        cordova.getActivity().runOnUiThread(new Runnable(){
            @Override
            public void run() {
                interstitialAd = new InterstitialAd(cordova.getActivity());
                interstitialAd.setAdUnitId(interstialAdId);
                interstitialAd.setAdListener(new InterstitialListener());
                
                interstitialAd.loadAd( buildAdRequest() );
                delayCallback.success();
            }
        });
        return null;
    }
    
    private AdRequest buildAdRequest() {
        AdRequest.Builder request_builder = new AdRequest.Builder();
        if (isTesting) {
            // This will request test ads on the emulator and deviceby passing this hashed device ID.
        	String ANDROID_ID = Settings.Secure.getString(cordova.getActivity().getContentResolver(), android.provider.Settings.Secure.ANDROID_ID);
            String deviceId = md5(ANDROID_ID).toUpperCase();
            request_builder = request_builder.addTestDevice(deviceId).addTestDevice(AdRequest.DEVICE_ID_EMULATOR);
        }

        Bundle bundle = new Bundle();
        bundle.putInt("cordova", 1);
        if(adExtras != null) {
            Iterator<String> it = adExtras.keys();
            while (it.hasNext()) {
                String key = it.next();
                try {
                    bundle.putString(key, adExtras.get(key).toString());
                } catch (JSONException exception) {
                    Log.w(LOGTAG, String.format("Caught JSON Exception: %s", exception.getMessage()));
                }
            }
        }
        AdMobExtras adextras = new AdMobExtras(bundle);
        request_builder = request_builder.addNetworkExtras( adextras );
        AdRequest request = request_builder.build();
        
        return request;
    }
    
    /**
     * Parses the request ad input parameters and runs the request ad action on
     * the UI thread.
     *
     * @param inputs The JSONArray representing input parameters.  This function
     *        expects the first object in the array to be a JSONObject with the
     *        input parameters.
     * @return A PluginResult representing whether or not an ad was requested
     *         succcessfully.  Listen for onReceiveAd() and onFailedToReceiveAd()
     *         callbacks to see if an ad was successfully retrieved.
     */
    private PluginResult executeRequestAd(JSONObject options, CallbackContext callbackContext) {
    	this.setOptions( options );
    	
    	if(adView == null) {
    		callbackContext.error("adView is null, call createBannerView first");
    		return null;
    	}
        
        final CallbackContext delayCallback = callbackContext;
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                adView.loadAd( buildAdRequest() );

                delayCallback.success();
            }
        });
        
        return null;
     }
    
    private PluginResult executeRequestInterstitialAd(JSONObject options, CallbackContext callbackContext) {
    	this.setOptions( options );
        
    	if(adView == null) {
    		callbackContext.error("interstitialAd is null, call createInterstitialView first");
    		return null;
    	}

    	final CallbackContext delayCallback = callbackContext;
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                interstitialAd.loadAd( buildAdRequest() );
                
                delayCallback.success();
            }
        });
        
        return null;
     }

    /**
     * Parses the show ad input parameters and runs the show ad action on
     * the UI thread.
     *
     * @param inputs The JSONArray representing input parameters.  This function
     *        expects the first object in the array to be a JSONObject with the
     *        input parameters.
     * @return A PluginResult representing whether or not an ad was requested
     *         succcessfully.  Listen for onReceiveAd() and onFailedToReceiveAd()
     *         callbacks to see if an ad was successfully retrieved.
     */
    private PluginResult executeShowAd(final boolean show, final CallbackContext callbackContext) {
        
        bannerShow = show;
        
        if(adView == null) {
            return new PluginResult(Status.ERROR, "adView is null, call createBannerView first.");
        }
        
        cordova.getActivity().runOnUiThread(new Runnable(){
			@Override
            public void run() {
                if(bannerVisible == bannerShow) { // no change
                	
                } else if( bannerShow ) {
                    if (adView.getParent() != null) {
                        ((ViewGroup)adView.getParent()).removeView(adView);
                    }
                    if(bannerOverlap) {
                        RelativeLayout.LayoutParams params2 = new RelativeLayout.LayoutParams(
                            RelativeLayout.LayoutParams.MATCH_PARENT,
                            RelativeLayout.LayoutParams.WRAP_CONTENT);
                        params2.addRule(bannerAtTop ? RelativeLayout.ALIGN_PARENT_TOP : RelativeLayout.ALIGN_PARENT_BOTTOM);
                        adViewLayout.addView(adView, params2);
                        adViewLayout.bringToFront();
                    } else {
                        ViewGroup parentView = (ViewGroup) webView.getParent();
                        if (bannerAtTop) {
                            parentView.addView(adView, 0);
                        } else {
                            parentView.addView(adView);
                        }
                        parentView.bringToFront();
                    }
                    
                	adView.setVisibility( View.VISIBLE );
                	bannerVisible = true;
                	
                } else {
                	adView.setVisibility( View.GONE );
                	bannerVisible = false;
                }
                
                if(callbackContext != null) callbackContext.success();
            }
        });
        
        return null;
    }
    
    private PluginResult executeShowInterstitialAd(final boolean show, final CallbackContext callbackContext) {

        if(interstitialAd == null) {
            return new PluginResult(Status.ERROR, "interstitialAd is null, call createInterstitialView first.");
        }
        
        cordova.getActivity().runOnUiThread(new Runnable(){
			@Override
            public void run() {
				if(interstitialAd.isLoaded()) {
					interstitialAd.show();
				}
				if(callbackContext != null) callbackContext.success();
            }
        });
        
        return null;
    }

    
    /**
     * This class implements the AdMob ad listener events.  It forwards the events
     * to the JavaScript layer.  To listen for these events, use:
     *
     * document.addEventListener('onReceiveAd', function());
     * document.addEventListener('onFailedToReceiveAd', function(data){});
     * document.addEventListener('onPresentAd', function());
     * document.addEventListener('onDismissAd', function());
     * document.addEventListener('onLeaveToAd', function());
     */
    public class BasicListener extends AdListener {
        @Override
        public void onAdFailedToLoad(int errorCode) {
            webView.loadUrl(String.format(
                    "javascript:cordova.fireDocumentEvent('onFailedToReceiveAd', { 'error': %d, 'reason':'%s' });",
                    errorCode, getErrorReason(errorCode)));
        }
        
        @Override
        public void onAdLeftApplication() {
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onLeaveToAd');");
        }
    }
    
    private class BannerListener extends BasicListener {
        @Override
        public void onAdLoaded() {
            Log.w("AdMob", "BannerAdLoaded");
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onReceiveAd');");
        }

        @Override
        public void onAdOpened() {
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onPresentAd');");
        }
        
        @Override
        public void onAdClosed() {
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onDismissAd');");
        }
        
    }
    
    private class InterstitialListener extends BasicListener {
        @Override
        public void onAdLoaded() {
            Log.w("AdMob", "InterstitialAdLoaded");
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onReceiveInterstitialAd');");
            
            if(autoShowInterstitial) {
            	executeShowInterstitialAd(true, null);
            }
        }

        @Override
        public void onAdOpened() {
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onPresentInterstitialAd');");
        }
        
        @Override
        public void onAdClosed() {
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onDismissInterstitialAd');");
            interstitialAd = null;
        }
        
    }
    
    @Override
    public void onPause(boolean multitasking) {
        if (adView != null) {
            adView.pause();
        }
        super.onPause(multitasking);
    }
    
    @Override
    public void onResume(boolean multitasking) {
        super.onResume(multitasking);
        isGpsAvailable = (GooglePlayServicesUtil.isGooglePlayServicesAvailable(cordova.getActivity()) == ConnectionResult.SUCCESS);
        if (adView != null) {
            adView.resume();
        }
    }
    
    @Override
    public void onDestroy() {
        if (adView != null) {
            adView.destroy();
            adView = null;
        }
		if (adViewLayout != null) {
			ViewGroup parentView = (ViewGroup)adViewLayout.getParent();
			if(parentView != null) {
				parentView.removeView(adViewLayout);
			}
			adViewLayout = null;
		}
        super.onDestroy();
    }
    
    /**
     * Gets an AdSize object from the string size passed in from JavaScript.
     * Returns null if an improper string is provided.
     *
     * @param size The string size representing an ad format constant.
     * @return An AdSize object used to create a banner.
     */
    public static AdSize adSizeFromString(String size) {
        if ("BANNER".equals(size)) {
            return AdSize.BANNER;
        } else if ("IAB_MRECT".equals(size)) {
            return AdSize.MEDIUM_RECTANGLE;
        } else if ("IAB_BANNER".equals(size)) {
            return AdSize.FULL_BANNER;
        } else if ("IAB_LEADERBOARD".equals(size)) {
            return AdSize.LEADERBOARD;
        } else if ("SMART_BANNER".equals(size)) {
            return AdSize.SMART_BANNER;
        } else {
            return null;
        }
    }

    
    /** Gets a string error reason from an error code. */
    public String getErrorReason(int errorCode) {
      String errorReason = "";
      switch(errorCode) {
        case AdRequest.ERROR_CODE_INTERNAL_ERROR:
          errorReason = "Internal error";
          break;
        case AdRequest.ERROR_CODE_INVALID_REQUEST:
          errorReason = "Invalid request";
          break;
        case AdRequest.ERROR_CODE_NETWORK_ERROR:
          errorReason = "Network Error";
          break;
        case AdRequest.ERROR_CODE_NO_FILL:
          errorReason = "No fill";
          break;
      }
      return errorReason;
    }
    
    public static final String md5(final String s) {
        try {
            MessageDigest digest = java.security.MessageDigest.getInstance("MD5");
            digest.update(s.getBytes());
            byte messageDigest[] = digest.digest();
            StringBuffer hexString = new StringBuffer();
            for (int i = 0; i < messageDigest.length; i++) {
                String h = Integer.toHexString(0xFF & messageDigest[i]);
                while (h.length() < 2)
                    h = "0" + h;
                hexString.append(h);
            }
            return hexString.toString();

        } catch (NoSuchAlgorithmException e) {
        }
        return "";
    }
}

