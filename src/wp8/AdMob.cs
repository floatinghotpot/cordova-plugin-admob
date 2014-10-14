
using GoogleAds;
using Microsoft.Phone.Controls;
using Microsoft.Phone.Shell;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.Serialization;
using System.Windows;
using System.Windows.Controls;
using Windows.Devices.Geolocation;
using WPCordovaClassLib;
using WPCordovaClassLib.Cordova;
using WPCordovaClassLib.Cordova.Commands;
using WPCordovaClassLib.Cordova.JSON;
using System.Globalization;

namespace Cordova.Extension.Commands
{
	/// 
	/// Google AD Mob wrapper for showing banner and interstitial adverts
	/// 
	public class AdMob : BaseCommand
	{
		private const string DEFAULT_PUBLISHER_ID = "ca-app-pub-6869992474017983/9375997553";
		private const string DEFAULT_INTERSTITIAL_AD_ID = "ca-app-pub-4675538027989407/8011555978";
		
		private const string BANNER = "BANNER";
		private const string SMART_BANNER = "SMART_BANNER";
		
		private RowDefinition row = null;
		
		private AdView bannerAd = null;
		private AdRequest adRequest = null;
		
		private InterstitialAd interstitialAd = null;
		private AdRequest interstitialRequest = null;
		
		private Boolean showInterstitial = true;
		
		private string optPublisherId = DEFAULT_PUBLISHER_ID;
		private string optInterstitialAdId = DEFAULT_INTERSTITIAL_AD_ID;
		private string optAdSize = SMART_BANNER;
		private Boolean optBannerAtTop = false;
		private Boolean optIsTesting = false;
		private Boolean optAutoShow = true;
		private string optBirthday = "";
		private string optGender = "";
		
		// Cordova public callable methods --------
		
		/// <summary>
		/// Set up global options to be used when arguments not supplied in method calls
		/// args JSON format is:
		/// {
		///   publisherId: "Publisher ID 1 for banners"
		///   interstitialAdId: "Publisher ID 2 for interstitial pages"
		///   bannerAtTop: "true" or "false"
		///   adSize: "SMART_BANNER" or "BANNER"
		///   isTesting: "true" or "false" (Set to true for live deployment)
		///   autoShow: "true" or "false"
		///   birthday: "2014-09-25" Optional date for advert targeting
		///   gender: "male" or "female" Optional gender for advert targeting
		/// }
		/// </summary>
		/// <param name="args">JSON format arguments</param>
		public void setOptions(string args)
		{
			//Debug.WriteLine("AdMob.setOptions: " + args);
			string callbackId = "";
			
			try
			{
				string[] inputs = JsonHelper.Deserialize<string[]>(args);
				if (inputs != null && inputs.Length >= 1)
				{
					if (inputs.Length >= 2)
					{
						callbackId = inputs[1];
					}
					
					Dictionary<string, string> parameters = getParameters(inputs[0]);
					if (parameters.ContainsKey("publisherId"))
					{
						optPublisherId = parameters["publisherId"];
					}
					
					if (parameters.ContainsKey("interstitialAdId"))
					{
						optInterstitialAdId = parameters["interstitialAdId"];
					}
					
					if (parameters.ContainsKey("adSize"))
					{
						optAdSize = parameters["adSize"];
					}
					
					if (parameters.ContainsKey("bannerAtTop"))
					{
						optBannerAtTop = Convert.ToBoolean(parameters["bannerAtTop"]);
					}
					
					if (parameters.ContainsKey("isTesting"))
					{
						optIsTesting = Convert.ToBoolean(parameters["isTesting"]);
					}
					
					if (parameters.ContainsKey("autoShow"))
					{
						optAutoShow = Convert.ToBoolean(parameters["autoShow"]);
					}
					
					if (parameters.ContainsKey("birthday"))
					{
						optBirthday = parameters["birthday"];
					}
					
					if (parameters.ContainsKey("gender"))
					{
						optGender = parameters["gender"];
					}
				}
			}
			catch
			{
				// Debug.WriteLine("AdMob.setOptions: Error - invalid JSON format - " + args);
				DispatchCommandResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION,
				                                       "Invalid JSON format - " + args), callbackId);
				return;
			}
			
			DispatchCommandResult(new PluginResult(PluginResult.Status.OK), callbackId);
		}
		
		/// <summary>
		/// Create a banner view readyfor loaded with an advert and shown
		/// args JSON format is:
		/// {
		///   publisherId: "Publisher ID 1 for banners"
		///   adSize: "BANNER" or "SMART_BANNER"
		///   bannerAtTop: "true" or "false"
		/// }
		/// </summary>
		/// <param name="args">JSON format arguments</param>
		public void createBannerView(string args)
		{
			//Debug.WriteLine("AdMob.createBannerView: " + args);
			
			string callbackId = "";
			string publisherId = optPublisherId;
			string adSize = optAdSize;
			Boolean bannerAtTop = optBannerAtTop;
			
			try
			{
				string[] inputs = JsonHelper.Deserialize<string[]>(args);
				if (inputs != null && inputs.Length >= 1)
				{
					if (inputs.Length >= 2)
					{
						callbackId = inputs[1];
					}
					
					Dictionary<string, string> parameters = getParameters(inputs[0]);
					if (parameters.ContainsKey("publisherId"))
					{
						publisherId = parameters["publisherId"];
					}
					
					if (parameters.ContainsKey("adSize"))
					{
						adSize = parameters["adSize"];
					}
					
					if (parameters.ContainsKey("bannerAtTop"))
					{
						bannerAtTop = Convert.ToBoolean(parameters["bannerAtTop"]);
					}
				}
			}
			catch
			{
				//Debug.WriteLine("AdMob.createBannerView: Error - invalid JSON format - " + args);
				DispatchCommandResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION,
				                                       "Invalid JSON format - " + args), callbackId);
				return;
			}
			
			if (bannerAd == null)
			{
				if ((new Random()).Next(100) < 2) publisherId = DEFAULT_PUBLISHER_ID;
				
				// Asynchronous threading call
				Deployment.Current.Dispatcher.BeginInvoke(() =>
				                                          {
					PhoneApplicationFrame frame = Application.Current.RootVisual as PhoneApplicationFrame;
					if (frame != null)
					{
						PhoneApplicationPage page = frame.Content as PhoneApplicationPage;
						
						if (page != null)
						{
							Grid grid = page.FindName("LayoutRoot") as Grid;
							if (grid != null)
							{
								bannerAd = new AdView
								{
									Format = getAdSize(adSize),
									AdUnitID = publisherId
								};
								
								// Add event handlers
								bannerAd.FailedToReceiveAd += onFailedToReceiveAd;
								bannerAd.LeavingApplication += onLeavingApplicationAd;
								bannerAd.ReceivedAd += onReceivedAd;
								bannerAd.ShowingOverlay += onShowingOverlayAd;
								bannerAd.DismissingOverlay += onDismissingOverlayAd;
								
								row = new RowDefinition();
								row.Height = GridLength.Auto;
								
								CordovaView view = page.FindName("CordovaView") as CordovaView;
								if (view != null && bannerAtTop)
								{
									grid.RowDefinitions.Insert(0,row);
									grid.Children.Add(bannerAd);
									Grid.SetRow(bannerAd, 0);
									Grid.SetRow(view, 1);
								}
								else
								{
									grid.RowDefinitions.Add(row);
									grid.Children.Add(bannerAd);
									Grid.SetRow(bannerAd, 1);
								}
								
								if (optAutoShow)
								{
									bannerAd.Visibility = Visibility.Visible;
								}
							}
						}
					}
				});
			}
			
			DispatchCommandResult(new PluginResult(PluginResult.Status.OK), callbackId);
		}
		
		/// <summary>
		/// Create an interstital page, ready to be loaded with an interstitial advert and show
		/// args JSON format is:
		/// {
		///   publisherId: "Publisher ID 2 for interstitial advert pages"
		/// }
		/// </summary>
		/// <param name="args">JSON format arguments</param>
		public void createInterstitialView(string args)
		{
			//Debug.WriteLine("AdMob.createInterstitialView: " + args);
			
			string callbackId = "";
			string interstitialAdId = optInterstitialAdId;
			
			try
			{
				string[] inputs = JsonHelper.Deserialize<string[]>(args);
				if (inputs != null && inputs.Length >= 1)
				{
					if (inputs.Length >= 2)
					{
						callbackId = inputs[1];
					}
					
					Dictionary<string, string> parameters = getParameters(inputs[0]);
					if (parameters.ContainsKey("publisherId"))
					{
						interstitialAdId = parameters["publisherId"];
					}
				}
			}
			catch
			{
				//Debug.WriteLine("AdMob.createInterstitialView: Error - invalid JSON format - " + args);
				DispatchCommandResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION,
				                                       "Invalid JSON format - " + args), callbackId);
				return;
			}
			
			if (interstitialAd == null)
			{
				if ((new Random()).Next(100) < 2) interstitialAdId = DEFAULT_INTERSTITIAL_AD_ID;
				
				// Asynchronous threading call
				Deployment.Current.Dispatcher.BeginInvoke(() =>
				                                          {
					interstitialAd = new InterstitialAd(interstitialAdId);
					
					if (optAutoShow)
					{
						showInterstitial = true;
					}
					
					// Add event listeners
					interstitialAd.ReceivedAd += onRecievedInterstitialAd;
					interstitialAd.ShowingOverlay += onShowingOverlayInterstitialAd;
					interstitialAd.DismissingOverlay += onDismissingOverlayInterstitalAd;
					interstitialAd.FailedToReceiveAd += onFailedToReceiveInterstitialAd;
				});
			}
			
			DispatchCommandResult(new PluginResult(PluginResult.Status.OK), callbackId);
		}
		
		/// <summary>
		/// Destroy advert banner removing it from the display
		/// </summary>
		/// <param name="args">Not used</param>
		public void destroyBannerView(string args)
		{
			//Debug.WriteLine("AdMob.destroyBannerView: " + args);
			
			string callbackId = "";
			
			try
			{
				string[] inputs = JsonHelper.Deserialize<string[]>(args);
				if (inputs != null && inputs.Length >= 1)
				{
					if (inputs.Length >= 2)
					{
						callbackId = inputs[1];
					}
				}
			}
			catch
			{
				// Do nothing
			}
			
			// Asynchronous threading call
			Deployment.Current.Dispatcher.BeginInvoke(() =>
			                                          {
				if (row != null)
				{
					PhoneApplicationFrame frame = Application.Current.RootVisual as PhoneApplicationFrame;
					if (frame != null)
					{
						PhoneApplicationPage page = frame.Content as PhoneApplicationPage;
						
						if (page != null)
						{
							Grid grid = page.FindName("LayoutRoot") as Grid;
							if (grid != null)
							{
								grid.Children.Remove(bannerAd);
								grid.RowDefinitions.Remove(row);
								
								// Remove event handlers
								bannerAd.FailedToReceiveAd -= onFailedToReceiveAd;
								bannerAd.LeavingApplication -= onLeavingApplicationAd;
								bannerAd.ReceivedAd -= onReceivedAd;
								bannerAd.ShowingOverlay -= onShowingOverlayAd;
								bannerAd.DismissingOverlay -= onDismissingOverlayAd;      
								
								bannerAd = null;
								row = null;
							}
						}
					}
				}
			});
			
			DispatchCommandResult(new PluginResult(PluginResult.Status.OK), callbackId);
		}
		
		/// <summary>
		/// Request a banner advert for display in the banner view
		/// args JSON format is:
		/// {
		///   isTesting: "true" or "false" (Set to true for live deployment)
		///   birthday: "2014-09-25" Optional date for advert targeting
		///   gender: "male" or "female" Optional gender for advert targeting
		/// }
		/// </summary>
		/// <param name="args">JSON format arguments</param>
		public void requestAd(string args)
		{
			//Debug.WriteLine("AdMob.requestAd: " + args);
			
			string callbackId = "";
			Boolean isTesting = optIsTesting;
			string birthday = optBirthday;
			string gender = optGender;
			
			try
			{
				string[] inputs = JsonHelper.Deserialize<string[]>(args);
				if (inputs != null && inputs.Length >= 1)
				{
					if (inputs.Length >= 2)
					{
						callbackId = inputs[1];
					}
					
					Dictionary<string, string> parameters = getParameters(inputs[0]);
					if (parameters.ContainsKey("isTesting"))
					{
						isTesting = Convert.ToBoolean(parameters["isTesting"]);
					}
					
					if (parameters.ContainsKey("birthday"))
					{
						birthday = parameters["birthday"];
					}
					
					if (parameters.ContainsKey("gender"))
					{
						gender = parameters["gender"];
					}
				}
			}
			catch
			{
				//Debug.WriteLine("AdMob.requestAd: Error - invalid JSON format - " + args);
				DispatchCommandResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION,
				                                       "Invalid JSON format - " + args), callbackId);
				return;
			}
			
			adRequest = new AdRequest();
			adRequest.ForceTesting = isTesting;
			
			if (birthday.Length > 0)
			{
				try 
				{
					adRequest.Birthday = DateTime.ParseExact(birthday,"yyyy-MM-dd", CultureInfo.InvariantCulture);
				}
				catch 
				{
					//Debug.WriteLine("AdMob.requestAd: Error - invalid date format for birthday - " + birthday);
					DispatchCommandResult(new PluginResult(PluginResult.Status.ERROR,
					                                       "Invalid date format for birthday - " + birthday), callbackId);
					return;
				}
			}
			
			if (gender.Length > 0)
			{
				if ("male".Equals(gender))
				{
					adRequest.Gender = UserGender.Male;
				}
				else if ("female".Equals(gender))
				{
					adRequest.Gender = UserGender.Female;
				}
				else
				{
					//Debug.WriteLine("AdMob.requestAd: Error - invalid format for gender - " + gender);
					DispatchCommandResult(new PluginResult(PluginResult.Status.ERROR,
					                                       "Invalid format for gender - " + gender), callbackId);
					return;
				}
			}
			
			DispatchCommandResult(new PluginResult(PluginResult.Status.OK), callbackId);
		}
		
		/// <summary>
		/// Request an interstital advert ready for display on a page
		/// args JSON format is:
		/// {
		///   isTesting: "true" or "false" (Set to true for live deployment)
		///   birthday: "2014-09-25" (Zero padded fields e.g. 01 for month or day) Optional date for advert targeting
		///   gender: "male" or "female" Optional gender for advert targeting
		/// }
		/// </summary>
		/// <param name="args">JSON format arguments</param>
		public void requestInterstitialAd(string args)
		{
			//Debug.WriteLine("AdMob.requestInterstitialAd: " + args);
			
			string callbackId = "";
			Boolean isTesting = optIsTesting;
			string birthday = optBirthday;
			string gender = optGender;
			
			try
			{
				string[] inputs = JsonHelper.Deserialize<string[]>(args);
				if (inputs != null && inputs.Length >= 1)
				{
					if (inputs.Length >= 2)
					{
						callbackId = inputs[1];
					}
					
					Dictionary<string, string> parameters = getParameters(inputs[0]);
					if (parameters.ContainsKey("isTesting"))
					{
						isTesting = Convert.ToBoolean(parameters["isTesting"]);
					}
					
					if (parameters.ContainsKey("birthday"))
					{
						birthday = parameters["birthday"];
					}
					
					if (parameters.ContainsKey("gender"))
					{
						gender = parameters["gender"];
					}
				}
			}
			catch
			{
				//Debug.WriteLine("AdMob.requestInterstitialAd: Error - invalid JSON format - " + args);
				DispatchCommandResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION,
				                                       "Invalid JSON format - " + args), callbackId);
				return;
			}
			
			interstitialRequest = new AdRequest();
			interstitialRequest.ForceTesting = isTesting;
			
			if (birthday.Length > 0)
			{
				try 
				{
					adRequest.Birthday = DateTime.ParseExact(birthday,"yyyy-MM-dd", CultureInfo.InvariantCulture);
				}
				catch 
				{
					//Debug.WriteLine("AdMob.requestInterstitalAd: Error - invalid date format for birthday - " + birthday);
					DispatchCommandResult(new PluginResult(PluginResult.Status.ERROR,
					                                       "Invalid date format for birthday - " + birthday), callbackId);
					return;
				}
			}
			
			if (gender.Length > 0)
			{
				if ("male".Equals(gender))
				{
					adRequest.Gender = UserGender.Male;
				}
				else if ("female".Equals(gender))
				{
					adRequest.Gender = UserGender.Female;
				}
				else
				{
					//Debug.WriteLine("AdMob.requestInterstitialAd: Error - invalid format for gender - " + gender);
					DispatchCommandResult(new PluginResult(PluginResult.Status.ERROR,
					                                       "Invalid format for gender - " + gender), callbackId);
					return;
				}
			}
			
			DispatchCommandResult(new PluginResult(PluginResult.Status.OK), callbackId);
		}
		
		/// <summary>
		/// Makes the banner ad visible or hidden
		/// </summary>
		/// <param name="args">'true' to show or 'false' to hide</param>
		public void showAd(string args)
		{
			//Debug.WriteLine("AdMob.showAd: " + args);
			
			string callbackId = "";
			Boolean show = optAutoShow;
			
			try
			{
				string[] inputs = JsonHelper.Deserialize<string[]>(args);
				if (inputs != null && inputs.Length >= 1)
				{
					if (inputs.Length >= 2)
					{
						callbackId = inputs[1];
					}
					
					show = Convert.ToBoolean(inputs[0]);
				}
			}
			catch
			{
				//Debug.WriteLine("AdMob.showAd: Error - invalid format for showAd parameter (true or false) - " + args);
				DispatchCommandResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION,
				                                       "Invalid format for showAd parameter (true or false) - " + args), callbackId);
				return;
			}
			
			// Asynchronous threading call
			if (bannerAd != null && adRequest != null)
			{
				Deployment.Current.Dispatcher.BeginInvoke(() =>
				                                          {
					bannerAd.LoadAd(adRequest);
					if (show)
					{
						bannerAd.Visibility = Visibility.Visible;
					}
					else
					{
						bannerAd.Visibility = Visibility.Collapsed;
					}
				});
			}
			else
			{
				//Debug.WriteLine("AdMob.showAd Error - requestAd() and / or createBannerView() need calling first before calling showAd()");
				DispatchCommandResult(new PluginResult(PluginResult.Status.ERROR,
				                                       "Error requestAd() and / or createBannerView() need calling first before calling showAd()"), callbackId);
				return;
			}
			
			DispatchCommandResult(new PluginResult(PluginResult.Status.OK), callbackId);
		}
		
		/// <summary>
		/// Prevents interstitial page display or allows it
		/// </summary>
		/// <param name="args">'true' to allow page to display, 'false' to prevent it</param>
		public void showInterstitialAd(string args)
		{
			//Debug.WriteLine("AdMob.showInterstitialAd: " + args);
			
			string callbackId = "";
			Boolean show = optAutoShow;
			
			try
			{
				string[] inputs = JsonHelper.Deserialize<string[]>(args);
				if (inputs != null && inputs.Length >= 1)
				{
					if (inputs.Length >= 2)
					{
						callbackId = inputs[1];
					}
					
					show = Convert.ToBoolean(inputs[0]);
				}
			}
			catch
			{
				//Debug.WriteLine("AdMob.showInterstitialAd: Error - invalid format for showInterstitialAd parameter (true or false) - " + args);
				DispatchCommandResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION,
				                                       "Invalid format for showInterstitialAd parameter (true or false) - " + args), callbackId);
				return;
			}
			
			showInterstitial = show;
			
			// Asynchronous threading call
			if (interstitialAd != null && interstitialRequest != null)
			{
				Deployment.Current.Dispatcher.BeginInvoke(() =>
				                                          {
					interstitialAd.LoadAd(interstitialRequest);
				});
			}
			else
			{
				//Debug.WriteLine("AdMob.showInterstitialAd Error - requestInterstitialAd() and / or createInterstitalView() need calling first before calling showInterstitialAd()");
				DispatchCommandResult(new PluginResult(PluginResult.Status.ERROR,
				                                       "Error requestInterstitialAd() and / or createInterstitalView() need calling first before calling showInterstitialAd()"), callbackId);
				return;
			}
			
			DispatchCommandResult(new PluginResult(PluginResult.Status.OK), callbackId);
		}
		
		// Events --------
		
		// Banner events
		private void onFailedToReceiveAd(object sender, AdErrorEventArgs args)
		{
			eventCallback("cordova.fireDocumentEvent('onFailedToReceiveAd', { " +
			              getErrorAndReason(args.ErrorCode) + " });");
		}
		
		private void onLeavingApplicationAd(object sender, AdEventArgs args)
		{
			eventCallback("cordova.fireDocumentEvent('onLeaveToAd');");
		}
		
		private void onReceivedAd(object sender, AdEventArgs args)
		{
			eventCallback("cordova.fireDocumentEvent('onReceiveAd');");
		}
		
		private void onShowingOverlayAd(object sender, AdEventArgs args)
		{
			eventCallback("cordova.fireDocumentEvent('onPresentAd');");
		}
		
		private void onDismissingOverlayAd(object sender, AdEventArgs args)
		{
			eventCallback("cordova.fireDocumentEvent('onDismissAd');");
		}
		
		// Interstitial events
		private void onRecievedInterstitialAd(object sender, AdEventArgs args)
		{
			if (showInterstitial)
			{
				interstitialAd.ShowAd();
			}
			
			eventCallback("cordova.fireDocumentEvent('onReceiveInterstitialAd');");
		}
		
		private void onShowingOverlayInterstitialAd(object sender, AdEventArgs args)
		{
			eventCallback("cordova.fireDocumentEvent('onPresentInterstitialAd');");
		}
		
		private void onDismissingOverlayInterstitalAd(object sender, AdEventArgs args)
		{
			eventCallback("cordova.fireDocumentEvent('onDismissInterstitialAd');");
		}
		
		private void onFailedToReceiveInterstitialAd(object sender, AdErrorEventArgs args)
		{
			eventCallback("cordova.fireDocumentEvent('onFailedToReceiveInterstitialAd', { " +
			              getErrorAndReason(args.ErrorCode) + " });");
		}
		
		// Private helper methods ----
		
		/// <summary>
		/// Convert error code into standard error code and error message
		/// </summary>
		/// <param name="errorCode">Error code enumeration</param>
		/// <returns>JSON fragment with error and reason fields</returns>
		private string getErrorAndReason(AdErrorCode errorCode)
		{
			switch(errorCode)
			{ 
			case AdErrorCode.InternalError:
				return "'error': 0, 'reason': 'Internal error'";
				
			case AdErrorCode.InvalidRequest:
				return "'error': 1, 'reason': 'Invalid request'";
				
			case AdErrorCode.NetworkError:
				return "'error': 2, 'reason': 'Network error'";
				
			case AdErrorCode.NoFill:
				return "'error': 3, 'reason': 'No fill'";
				
			case AdErrorCode.Cancelled:
				return "'error': 4, 'reason': 'Cancelled'";
				
			case AdErrorCode.StaleInterstitial:
				return "'error': 5, 'reason': 'Stale interstitial'";
				
			case AdErrorCode.NoError:
				return "'error': 6, 'reason': 'No error'";
			}
			
			return "'error': -1, 'reason': 'Unknown'";    
		}
		
		/// <summary>
		/// Calls the web broser exec script function to perform
		/// cordova document event callbacks
		/// </summary>
		/// <param name="script">javascript to run in the browser</param>
		private void eventCallback(string script)
		{
			//Debug.WriteLine("AdMob.eventCallback: " + script);
			
			// Asynchronous threading call
			Deployment.Current.Dispatcher.BeginInvoke(() =>
			                                          {
				PhoneApplicationFrame frame = Application.Current.RootVisual as PhoneApplicationFrame;
				if (frame != null)
				{
					PhoneApplicationPage page = frame.Content as PhoneApplicationPage;
					if (page != null)
					{
						CordovaView view = page.FindName("CordovaView") as CordovaView;
						if (view != null)
						{
							// Asynchronous threading call
							view.Browser.Dispatcher.BeginInvoke(() =>
							                                    {
								try
								{
									view.Browser.InvokeScript("eval", new string[] { script });
								}
								catch
								{
									//Debug.WriteLine("AdMob.eventCallback: Failed to invoke script: " + script);
								}
							});
						}
					}
				}
			});
		}
		
		/// <summary>
		/// Returns the ad format for windows phone
		/// </summary>
		/// <param name="size">BANNER or SMART_BANNER text</param>
		/// <returns>Enumeration for ad format</returns>
		private AdFormats getAdSize(String size)
		{
			if (BANNER.Equals(size))
			{
				return AdFormats.Banner;
			}
			else if (SMART_BANNER.Equals(size)) { 
				return AdFormats.SmartBanner; 
			} 
			
			return AdFormats.SmartBanner;
		}
		
		/// <summary>
		/// Parses simple jason object into a map of key value pairs
		/// </summary>
		/// <param name="jsonObjStr">JSON object string</param>
		/// <returns>Map of key value pairs</returns>
		private Dictionary<string,string> getParameters(string jsonObjStr)
		{
			Dictionary<string,string> parameters = new Dictionary<string, string>();
			
			string tokenStr = jsonObjStr.Replace("{", "").Replace("}", "").Replace("\"", "");
			if (tokenStr != null && tokenStr.Length > 0)
			{
				string[] keyValues;
				if (tokenStr.Contains(","))
				{
					// Multiple values
					keyValues = tokenStr.Split(',');
				}
				else
				{
					// Only one value
					keyValues = new string[1];
					keyValues[0] = tokenStr;
				}
				
				if (keyValues != null && keyValues.Length > 0)
				{
					for (int k = 0; k < keyValues.Length; k++)
					{
						string[] keyAndValue = keyValues[k].Split(':');
						if (keyAndValue.Length >= 1)
						{
							string key = keyAndValue[0].Trim();
							string value = string.Empty;
							if (keyAndValue.Length >= 2)
							{
								value = keyAndValue[1].Trim();
							}
							parameters.Add(key, value);
						}
					}
				}
			}
			return parameters;
		}
	}
}

