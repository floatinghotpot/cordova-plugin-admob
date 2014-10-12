using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.Serialization;
using System.Windows;
using WPCordovaClassLib.Cordova;
using WPCordovaClassLib.Cordova.Commands;
using WPCordovaClassLib.Cordova.JSON;
using GoogleAds;

using System.Windows.Controls;
using Microsoft.Phone.Controls;
using Microsoft.Phone.Shell;
using System.Diagnostics;

namespace Cordova.Extension.Commands
{
	public class AdMob : BaseCommand
	{
		private AdView bannerAd;
		private AdRequest adRequest;
		
		private InterstitialAd interstitialAd;
		private AdRequest interstitialRequest;
		
		private string optPublisherId = "";
		private string optInterstitialAdId = "";
		private Boolean optBannerAtTop = false;
		private Boolean optOverlap = false;
		private Boolean optOffsetTopBar = false;
		private Boolean optIsTesting = false;
		private Boolean optAutoShow = true;
		
		public void setOptions(string args)
		{
			try
			{
				String[] inputs = JsonHelper.Deserialize<string[]>(args);
				if (inputs != null && inputs.Length >= 1)
				{
					Dictionary<string, string> parameters = getParameters(inputs[0]);
					if (parameters.ContainsKey("publisherId"))
					{
						optPublisherId = parameters["publisherId"];
					}
					
					if (parameters.ContainsKey("interstitialAdId"))
					{
						optInterstitialAdId = parameters["interstitialAdId"];
					}
					
					if (parameters.ContainsKey("bannerAtTop"))
					{
						optBannerAtTop = Convert.ToBoolean(parameters["bannerAtTop"]);
					}
					
					if (parameters.ContainsKey("overlap"))
					{
						optOverlap = Convert.ToBoolean(parameters["overlap"]);
					}
					
					if (parameters.ContainsKey("offsetTopBar"))
					{
						optOffsetTopBar = Convert.ToBoolean(parameters["offsetTopBar"]);
					}
					
					if (parameters.ContainsKey("isTesting"))
					{
						optIsTesting = Convert.ToBoolean(parameters["isTesting"]);
					}
					
					if (parameters.ContainsKey("autoShow"))
					{
						optAutoShow = Convert.ToBoolean(parameters["autoShow"]);
					}
				}
			}
			catch
			{
				DispatchCommandResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
				return;
			}
			
			this.DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
		}
		
		public void createBannerView(string args)
		{
			string publisherId = optPublisherId;
			string adSize = "BANNER";
			
			try
			{
				String[] inputs = JsonHelper.Deserialize<string[]>(args);
				if (inputs != null && inputs.Length >= 1)
				{
					Dictionary<string, string> parameters = getParameters(inputs[0]);
					if (parameters.ContainsKey("publisherId"))
					{
						publisherId = parameters["publisherId"];
					}
					
					if (parameters.ContainsKey("adSize"))
					{
						adSize = parameters["adSize"];
					}
				}
				
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
								RowDefinition row = new RowDefinition();
								row.Height = GridLength.Auto;
								grid.RowDefinitions.Add(row);
								
								bannerAd = new AdView
								{
									Format = getAdSize(adSize),
									AdUnitID = publisherId
								};
								
								bannerAd.FailedToReceiveAd += OnFailedToReceiveAd;
								
								grid.Children.Add(bannerAd);
								Grid.SetRow(bannerAd, 1);
							}
						}
					}
					
					this.DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
				});
			}
			catch
			{
				DispatchCommandResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
				return;
			}
		}
		
		public void createInterstitialView(string args)
		{
			string interstitialAdId = optInterstitialAdId;
			
			try
			{
				String[] inputs = JsonHelper.Deserialize<string[]>(args);
				if (inputs != null && inputs.Length >= 1)
				{
					Dictionary<string, string> parameters = getParameters(inputs[0]);
					if (parameters.ContainsKey("publisherId"))
					{
						interstitialAdId = parameters["publisherId"];
					}
				}
				
				Deployment.Current.Dispatcher.BeginInvoke(() =>
				                                          {
					interstitialAd = new InterstitialAd(interstitialAdId);
					interstitialAd.ReceivedAd += OnInterstitialAdReceived;
					interstitialAd.FailedToReceiveAd += OnFailedToReceiveInterstitialAd;
					
					this.DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
				});
			}
			catch
			{
				DispatchCommandResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
				return;
			}
		}
		
		public void destroyBannerView(string args)
		{
			this.DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
		}
		
		public void requestAd(string args)
		{
			Boolean isTesting = optIsTesting;
			
			try
			{
				String[] inputs = JsonHelper.Deserialize<string[]>(args);
				if (inputs != null && inputs.Length >= 1)
				{
					Dictionary<string, string> parameters = getParameters(inputs[0]);
					if (parameters.ContainsKey("isTesting"))
					{
						isTesting = Convert.ToBoolean(parameters["isTesting"]);
					}
				}
			}
			catch
			{
				DispatchCommandResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
				return;
			}
			
			adRequest = new AdRequest();
			adRequest.ForceTesting = isTesting;
			
			this.DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
		}
		
		public void requestInterstitialAd(string args)
		{
			Boolean isTesting = optIsTesting;
			
			try
			{
				String[] inputs = JsonHelper.Deserialize<string[]>(args);
				if (inputs != null && inputs.Length >= 1)
				{
					Dictionary<string, string> parameters = getParameters(inputs[0]);
					if (parameters.ContainsKey("isTesting"))
					{
						isTesting = Convert.ToBoolean(parameters["isTesting"]);
					}
				}
			}
			catch
			{
				DispatchCommandResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
				return;
			}
			
			interstitialRequest = new AdRequest();
			interstitialRequest.ForceTesting = isTesting;
			
			this.DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
		}
		
		public void showAd(string args)
		{
			Boolean show = optAutoShow;
			
			try
			{
				String[] inputs = JsonHelper.Deserialize<string[]>(args);
				if (inputs != null && inputs.Length >= 1)
				{
					show = Convert.ToBoolean(inputs[0]);
				}
			}
			catch
			{
				DispatchCommandResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
				return;
			}
			
			Deployment.Current.Dispatcher.BeginInvoke(() =>
			                                          {
				bannerAd.LoadAd(adRequest);
				this.DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
			});
		}
		
		public void showInterstitialAd(string args)
		{
			Boolean show = optAutoShow;
			
			try
			{
				String[] inputs = JsonHelper.Deserialize<string[]>(args);
				if (inputs != null && inputs.Length >= 1)
				{
					show = Convert.ToBoolean(inputs[0]);
				}
			}
			catch
			{
				DispatchCommandResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
				return;
			}
			
			Deployment.Current.Dispatcher.BeginInvoke(() =>
			                                          {
				interstitialAd.LoadAd(interstitialRequest);
				this.DispatchCommandResult(new PluginResult(PluginResult.Status.OK));
			});
		}
		
		private void OnFailedToReceiveAd(object sender, AdErrorEventArgs errorCode)
		{
			Debug.WriteLine("Failed to receive banner advert with error " + errorCode.ErrorCode);
		}
		
		private void OnInterstitialAdReceived(object sender, AdEventArgs e)
		{
			interstitialAd.ShowAd();
		}
		
		private void OnFailedToReceiveInterstitialAd(object sender, AdErrorEventArgs errorCode)
		{
			Debug.WriteLine("Failed to receive interstitial advert with error " + errorCode.ErrorCode);
		}
		
		private AdFormats getAdSize(String size)
		{
			if ("BANNER".Equals(size))
			{
				return AdFormats.Banner;
			}
			return AdFormats.SmartBanner;
		}
		
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
						String[] keyAndValue = keyValues[k].Split(':');
						if (keyAndValue.Length >= 1)
						{
							String key = keyAndValue[0].Trim();
							String value = String.Empty;
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

