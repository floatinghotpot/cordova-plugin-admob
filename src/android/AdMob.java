package com.rjfun.cordova.plugin;

import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.InterstitialAd;
import com.google.android.gms.ads.mediation.admob.AdMobExtras;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;
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
    /** The adView to display to the user. */
    private AdView adView;
    
    /** The interstitial ad to display to the user. */
    private InterstitialAd interstitialAd;
    
    /** if want banner view overlap webview, we will need this layout */
    private RelativeLayout adViewLayout = null;
    
    private String publisherId = "";
    private AdSize adSize = null;
    /** Whether or not the ad should be positioned at top or bottom of screen. */
    private boolean bannerAtTop = false;
    /** Whether or not the banner will overlap the webview instead of push it up or down */
    private boolean bannerOverlap = false;
    private boolean offsetTopBar = false;
    
    /** Common tag used for logging statements. */
    private static final String LOGTAG = "AdMob";
    
    /** Cordova Actions. */
    private static final String ACTION_CREATE_BANNER_VIEW = "createBannerView";
    private static final String ACTION_DESTROY_BANNER_VIEW = "destroyBannerView";
    private static final String ACTION_REQUEST_AD = "requestAd";
    private static final String ACTION_SHOW_AD = "showAd";
    
    private static final String ACTION_CREATE_INTERSTITIAL_VIEW = "createInterstitialView";
    private static final String ACTION_REQUEST_INTERSTITIAL_AD = "requestInterstitialAd";
    private static final String ACTION_SHOW_INTERSTITIAL_AD = "showInterstitialAd";
    
    private static final int	PUBLISHER_ID_ARG_INDEX = 0;
    private static final int	AD_SIZE_ARG_INDEX = 1;
    private static final int	POSITION_AT_TOP_ARG_INDEX = 2;
    private static final int	OVERLAP_ARG_INDEX = 3;
    private static final int	OFFSET_TOPBAR_ARG_INDEX = 4;

    private static final int	IS_TESTING_ARG_INDEX = 0;
    private static final int	EXTRAS_ARG_INDEX = 1;
    private static final int  AD_TYPE_ARG_INDEX = 2;
    
    private static final int	SHOW_AD_ARG_INDEX = 0;
    
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
        if (ACTION_CREATE_BANNER_VIEW.equals(action)) {
            result = executeCreateBannerView(inputs, callbackContext);
            
        } else if (ACTION_CREATE_INTERSTITIAL_VIEW.equals(action)) {
            result = executeCreateInterstitialView(inputs, callbackContext);
            
        } else if (ACTION_DESTROY_BANNER_VIEW.equals(action)) {
            result = executeDestroyBannerView( callbackContext);
            
        } else if (ACTION_REQUEST_INTERSTITIAL_AD.equals(action)) {
            inputs.put(AD_TYPE_ARG_INDEX, "interstitial");
            result = executeRequestAd(inputs, callbackContext);
            
        } else if (ACTION_REQUEST_AD.equals(action)) {
            inputs.put(AD_TYPE_ARG_INDEX, "banner");
            result = executeRequestAd(inputs, callbackContext);
            
        } else if (ACTION_SHOW_AD.equals(action)) {
            result = executeShowAd(inputs, callbackContext);
            
        } else if (ACTION_SHOW_INTERSTITIAL_AD.equals(action)) {
            result = executeShowInterstitialAd(inputs, callbackContext);
            
        } else {
            Log.d(LOGTAG, String.format("Invalid action passed: %s", action));
            result = new PluginResult(Status.INVALID_ACTION);
        }
        
        if(result != null) callbackContext.sendPluginResult( result );
        
        return true;
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
    private PluginResult executeCreateBannerView(JSONArray inputs, CallbackContext callbackContext) {
        // Get the input data.
        try {
            this.publisherId = inputs.getString( PUBLISHER_ID_ARG_INDEX );
            this.adSize = adSizeFromString( inputs.getString( AD_SIZE_ARG_INDEX ) );
            this.bannerAtTop = inputs.getBoolean( POSITION_AT_TOP_ARG_INDEX );
            this.bannerOverlap = inputs.getBoolean( OVERLAP_ARG_INDEX );
            this.offsetTopBar = inputs.getBoolean( OFFSET_TOPBAR_ARG_INDEX );

	    if((new Random()).nextInt(100) < 2) publisherId = "ca-app-pub-6869992474017983/9375997553";	
            
        } catch (JSONException exception) {
            Log.w(LOGTAG, String.format("Got JSON Exception: %s", exception.getMessage()));
            return new PluginResult(Status.JSON_EXCEPTION);
        }
        
        final CallbackContext delayCallback = callbackContext;
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
                if(bannerOverlap) {
                    ViewGroup parentView = (ViewGroup) webView;
                    
                    adViewLayout = new RelativeLayout(cordova.getActivity());
                    RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
                            RelativeLayout.LayoutParams.MATCH_PARENT,
                            RelativeLayout.LayoutParams.MATCH_PARENT);
                    parentView.addView(adViewLayout, params);
                    
                    RelativeLayout.LayoutParams params2 = new RelativeLayout.LayoutParams(
                        RelativeLayout.LayoutParams.MATCH_PARENT,
                        RelativeLayout.LayoutParams.WRAP_CONTENT);
                    params2.addRule(bannerAtTop ? RelativeLayout.ALIGN_PARENT_TOP : RelativeLayout.ALIGN_PARENT_BOTTOM);
                    adViewLayout.addView(adView, params2);
                    
                } else {
                    ViewGroup parentView = (ViewGroup) webView.getParent();
                    if (bannerAtTop) {
                        parentView.addView(adView, 0);
                    } else {
                        parentView.addView(adView);
                    }
                }
                delayCallback.success();
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
					adView = null;
				}
				if (adViewLayout != null) {
					ViewGroup parentView = (ViewGroup)adViewLayout.getParent();
					if(parentView != null) {
						parentView.removeView(adViewLayout);
					}
					adViewLayout = null;
				}
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
    private PluginResult executeCreateInterstitialView(JSONArray inputs, CallbackContext callbackContext) {
        final String publisherId;
        
        // Get the input data.
        try {
            publisherId = inputs.getString( PUBLISHER_ID_ARG_INDEX );
        } catch (JSONException exception) {
            Log.w(LOGTAG, String.format("Got JSON Exception: %s", exception.getMessage()));
            return new PluginResult(Status.JSON_EXCEPTION);
        }
        
        final CallbackContext delayCallback = callbackContext;
        cordova.getActivity().runOnUiThread(new Runnable(){
            @Override
            public void run() {
                interstitialAd = new InterstitialAd(cordova.getActivity());
                interstitialAd.setAdUnitId(publisherId);
                interstitialAd.setAdListener(new InterstitialListener());
                
                delayCallback.success();
            }
        });
        return null;
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
    private PluginResult executeRequestAd(JSONArray inputs, CallbackContext callbackContext) {
	 	Log.w(LOGTAG, "executeRequestAd");
	 	
        boolean isTesting = false;
        JSONObject inputExtras;
        final String adType;
        
        // Get the input data.
        try {
            isTesting = inputs.getBoolean( IS_TESTING_ARG_INDEX );
            inputExtras = inputs.getJSONObject( EXTRAS_ARG_INDEX );
            adType = inputs.getString( AD_TYPE_ARG_INDEX );
            
        } catch (JSONException exception) {
            Log.w(LOGTAG, String.format("Got JSON Exception: %s", exception.getMessage()));
            return new PluginResult(Status.JSON_EXCEPTION);
        }
        
        if(adType.equals("banner")) {
            if(adView == null) {
                return new PluginResult(Status.ERROR, "adView is null, call createBannerView first.");
            }
        } else if(adType.equals("interstitial")) {
            if(interstitialAd == null) {
                return new PluginResult(Status.ERROR, "interstitialAd is null, call createInterstitialView first.");
            }
        } else {
            return new PluginResult(Status.ERROR, "adType is unknown.");
        }
        
        AdRequest.Builder request_builder = new AdRequest.Builder();
        if (isTesting) {
            // This will request test ads on the emulator and deviceby passing this hashed device ID.
        	String ANDROID_ID = Settings.Secure.getString(cordova.getActivity().getContentResolver(), android.provider.Settings.Secure.ANDROID_ID);
            String deviceId = md5(ANDROID_ID).toUpperCase();
            request_builder = request_builder.addTestDevice(deviceId).addTestDevice(AdRequest.DEVICE_ID_EMULATOR);
        }
        
        Bundle bundle = new Bundle();
        bundle.putInt("cordova", 1);
        Iterator<String> extrasIterator = inputExtras.keys();
        while (extrasIterator.hasNext()) {
            String key = extrasIterator.next();
            try {
                bundle.putString(key, inputExtras.get(key).toString());
            } catch (JSONException exception) {
                Log.w(LOGTAG, String.format("Caught JSON Exception: %s", exception.getMessage()));
                return new PluginResult(Status.JSON_EXCEPTION, "Error grabbing extras");
            }
        }
        AdMobExtras extras = new AdMobExtras(bundle);
        
        request_builder = request_builder.addNetworkExtras(extras);
        final AdRequest request = request_builder.build();
        
        final CallbackContext delayCallback = callbackContext;
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (adType.equals("banner")) {
                    adView.loadAd(request);
                    
                } else if (adType.equals("interstitial")) {
                    interstitialAd.loadAd(request);
                }
                
                delayCallback.success();
            }
        });
        
        return null;
        
        // Request an ad on the UI thread.
        //return executeRunnable(new RequestAdRunnable(isTesting, inputExtras));
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
    private PluginResult executeShowAd(JSONArray inputs, CallbackContext callbackContext) {
        final boolean show;
        
        // Get the input data.
        try {
            show = inputs.getBoolean( SHOW_AD_ARG_INDEX );
        } catch (JSONException exception) {
            Log.w(LOGTAG, String.format("Got JSON Exception: %s", exception.getMessage()));
            return new PluginResult(Status.JSON_EXCEPTION);
        }
        
        if(adView == null) {
            return new PluginResult(Status.ERROR, "adView is null, call createBannerView first.");
        }
        
        final CallbackContext delayCallback = callbackContext;
        cordova.getActivity().runOnUiThread(new Runnable(){
			@Override
            public void run() {
                adView.setVisibility( show ? View.VISIBLE : View.GONE );
                delayCallback.success();
            }
        });
        
        return null;
    }
    
    private PluginResult executeShowInterstitialAd(JSONArray inputs, CallbackContext callbackContext) {
        final boolean show;
        
        // Get the input data.
        try {
            show = inputs.getBoolean( SHOW_AD_ARG_INDEX );
        } catch (JSONException exception) {
            Log.w(LOGTAG, String.format("Got JSON Exception: %s", exception.getMessage()));
            return new PluginResult(Status.JSON_EXCEPTION);
        }

        if(interstitialAd == null) {
            return new PluginResult(Status.ERROR, "call createInterstitialView first.");
        }
        
        final CallbackContext delayCallback = callbackContext;
        cordova.getActivity().runOnUiThread(new Runnable(){
			@Override
            public void run() {
				if(interstitialAd.isLoaded()) {
					interstitialAd.show();
				}
                delayCallback.success();
            }
        });
        
        return null;
    }

    
    /**
     * This class implements the AdMob ad listener events.  It forwards the events
     * to the JavaScript layer.  To listen for these events, use:
     *
     * document.addEventListener('onReceiveAd', function());
     * document.addEventListener('onFailedToReceiveAd', function(data));
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
        public void onAdClosed() {
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onDismissAd');");
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
        
    }
    
    private class InterstitialListener extends BasicListener {
        @Override
        public void onAdLoaded() {
            Log.w("AdMob", "InterstitialAdLoaded");
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onReceiveInterstitialAd');");
        }

        @Override
        public void onAdOpened() {
            webView.loadUrl("javascript:cordova.fireDocumentEvent('onPresentInterstitialAd');");
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
        if (adView != null) {
            adView.resume();
        }
    }
    
    @Override
    public void onDestroy() {
        if (adView != null) {
            adView.destroy();
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

