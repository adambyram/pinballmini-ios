//
//  Storefront.m
//  PinballMini
//
//  Created by Adam Byram on 2/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#import <StoreKit/StoreKit.h>
#import "Storefront.h"
#import "cocos2d.h"
#import "PinballMiniConstants.h"
#import "CocosDenshion.h"
#import "CDAudioManager.h"
#import "Reachability.h"
#import "PinballMiniAppDelegate.h"
#import <SystemConfiguration/SystemConfiguration.h>

#define OFFSCREEN_BOTTOM_POSITION CGRectMake(0.0f, 480.0f, 320, 480.0f)
#define ONSCREEN_POSITION CGRectMake(0.0f,0.0f,320.0f,480.0f)
#define BUTTON_LEFT_POSITION CGRectMake(0.0f,430.0f,161.0f,33.0f)
#define BUTTON_RIGHT_POSITION CGRectMake(163.0f,430.0f,157.0f,33.0f)

@implementation Storefront

-(id)init
{
	if(self = [super init])
	{
		isShowing = NO;
		downloadOverlayActive = NO;
		storeManager = [(PinballMiniAppDelegate*)[[UIApplication sharedApplication] delegate] storeManager];
		[storeManager setDelegate:self];
		backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"StorefrontBackground.png"]];
		backgroundView.frame = OFFSCREEN_BOTTOM_POSITION;
		backgroundView.userInteractionEnabled = YES;
		
		UIButton* restoreButton = [[UIButton alloc] initWithFrame:CGRectMake(29.0f,429.0f,101.0f,33.0f)];
		[restoreButton setImage:[UIImage imageNamed:@"RestorePurchasesButton.png"] forState:UIControlStateNormal];
		[restoreButton addTarget:self action:@selector(restorePurchases:) forControlEvents:UIControlEventTouchUpInside];
		[backgroundView addSubview:restoreButton];
		[restoreButton release];
		
		UIButton* mainMenuButton = [[UIButton alloc] initWithFrame:CGRectMake(134.0f,429.0f,157.0f,33.0f)];
		[mainMenuButton setImage:[UIImage imageNamed:@"HighScore-MainMenu.png"] forState:UIControlStateNormal];
		[mainMenuButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
		[backgroundView addSubview:mainMenuButton];
		[mainMenuButton release];
		
		
		transparentBackgroundView = [[UIView alloc] initWithFrame:ONSCREEN_POSITION];
		transparentBackgroundView.alpha = 0.8f;
		transparentBackgroundView.backgroundColor = [UIColor blackColor];
		transparentBackgroundView.userInteractionEnabled = YES;
		
	
		stockingStoreView = [[UIView alloc] initWithFrame:ONSCREEN_POSITION];
		UIImageView* stockingImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LoadingStorefrontSticker.png"]];
		stockingImageView.frame = CGRectMake(29.0f,160.0f,263.0f,125.0f);
		UIActivityIndicatorView* stockingActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		stockingActivityIndicator.center = CGPointMake(stockingImageView.bounds.size.width/2.0f,(stockingImageView.bounds.size.height/2.0f) + 18.0f);
		[stockingActivityIndicator startAnimating];
		[stockingImageView addSubview:stockingActivityIndicator];
		[stockingActivityIndicator release];
		[stockingStoreView addSubview:stockingImageView];
		[stockingImageView release];
		
		downloadingContentView = [[UIView alloc] initWithFrame:ONSCREEN_POSITION];
		UIImageView* downloadingImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DownloadingItemsSticker.png"]];
		downloadingImageView.frame = CGRectMake(29.0f,160.0f,263.0f,125.0f);
		UIActivityIndicatorView* downloadingActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		downloadingActivityIndicator.center = CGPointMake(downloadingImageView.bounds.size.width/2.0f,(downloadingImageView.bounds.size.height/2.0f) + 18.0f);
		[downloadingActivityIndicator startAnimating];
		[downloadingImageView addSubview:downloadingActivityIndicator];
		[downloadingActivityIndicator release];
		[downloadingContentView addSubview:downloadingImageView];
		[downloadingImageView release];
	}
	return self;
}

-(void)dealloc
{
	[transparentBackgroundView release];
	[downloadingContentView release];
	[stockingStoreView release];
	[backgroundView release];
	[super dealloc];
}

- (void) hide
{
	isShowing = NO;
	[[CDAudioManager sharedManager].soundEngine playSound:PM_SOUND_BUTTONCLICK channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];

	backgroundView.frame = ONSCREEN_POSITION;
	[UIView beginAnimations:@"storefrontSlideDown" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDuration:SLIDE_SPEED];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(removeBackgroundView)];
	backgroundView.frame = OFFSCREEN_BOTTOM_POSITION;
	[UIView commitAnimations];	
}


- (void) restorePurchases:(id)sender
{
	[[CDAudioManager sharedManager].soundEngine playSound:PM_SOUND_BUTTONCLICK channelGroupId:PM_CHANNELGROUP_SOUNDEFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];

	NSLog(@"Restoring...");
	[storeManager restorePurchases];
}

- (void) showDownloadingOverlay
{
	if(!downloadOverlayActive)
	{
	downloadOverlayActive = YES;
	[[[[CCDirector sharedDirector] openGLView] window] addSubview:transparentBackgroundView];
	[[[[CCDirector sharedDirector] openGLView] window] addSubview:downloadingContentView];
	// For testing
	//[self performSelector:@selector(removeDownloadingOverlay) withObject:nil afterDelay:3.0f];
	}
}

- (void) removeDownloadingOverlay
{
if (downloadOverlayActive) {
		
	[downloadingContentView removeFromSuperview];
	[transparentBackgroundView removeFromSuperview];
	downloadOverlayActive = NO;
}
}

- (void) showStockingStoreOverlay
{
	[[[[CCDirector sharedDirector] openGLView] window] addSubview:transparentBackgroundView];
	[[[[CCDirector sharedDirector] openGLView] window] addSubview:stockingStoreView];
	// For testing
	//[self performSelector:@selector(removeStockingStoreOverlay) withObject:nil afterDelay:3.0f];
}



- (void) showStorefrontItems
{
	CGPoint offset = (packScrollView != nil)? packScrollView.contentOffset : CGPointMake(0.0f,0.0f);
	[packScrollView removeFromSuperview];
	[packScrollView release];
	
	float sidePadding = 1.0f;
	float startPositionY = 0.0f;
	float itemSpacing = 5.0f;
	float itemSizeY = 158.0f;
	float itemSizeX = 263.0f;
	NSArray* storeItems = [[storeManager storeItems] copy];
	
	packScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(28.0f,96.0f,265.0f,330.0f)];
	[packScrollView setCanCancelContentTouches:YES];
	packScrollView.backgroundColor = [UIColor clearColor];
	[backgroundView addSubview:packScrollView];
	UIView* contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0f,0.0f,265.0f,([storeItems count]*(itemSizeY+itemSpacing))-itemSpacing)];
	contentView.backgroundColor = [UIColor clearColor];
	[packScrollView addSubview:contentView];
	[packScrollView setContentSize:contentView.frame.size];
	//[packScrollView setContentInset:UIEdgeInsetsMake(20.0f, 0.0f, 20.0f, 0.0f)];
		
	NSNumberFormatter *currencyStyle = [[NSNumberFormatter alloc] init];
	[currencyStyle setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[currencyStyle setNumberStyle:NSNumberFormatterCurrencyStyle];
	
	
	
	int currentItem = 0;
	for(id storeItem in storeItems)
	{
		UIImageView* imageView = [[UIImageView alloc] initWithImage:([(NSNumber*)[storeItem objectForKey:@"Installed"] boolValue] == YES)?[storeItem objectForKey:@"PurchasedProductImage"]:[storeItem objectForKey:@"UnpurchasedProductImage"]];
		[imageView setUserInteractionEnabled:YES];
		imageView.frame = CGRectMake(sidePadding,startPositionY+(currentItem*(itemSizeY+itemSpacing)),itemSizeX,itemSizeY);
		UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(imageView.bounds.size.width-94.0f-5.0f,imageView.bounds.size.height-31.0f-5.0f,94.0f,31.0f)];
		[button setTag:currentItem];
		
		if([(NSNumber*)[storeItem objectForKey:@"Installed"] boolValue] == YES)
		{
			if([(NSNumber*)[storeItem objectForKey:@"UpgradeNeeded"] boolValue] == YES)
			{
				[button setImage:[UIImage imageNamed:@"StorefrontUpdateButton.png"] forState:UIControlStateNormal];
				[button addTarget:self action:@selector(updateProduct:) forControlEvents:UIControlEventTouchUpInside];
			}
			else
			{
				[button setImage:[UIImage imageNamed:@"StorefrontPurchasedButton.png"] forState:UIControlStateNormal];
				//[button addTarget:self action:@selector(updateProduct:) forControlEvents:UIControlEventTouchUpInside];
				[button setEnabled:NO];
			}

		}
		else if([(NSNumber*)[storeItem objectForKey:@"ViewOnly"] boolValue] == NO && [(NSNumber*)[storeItem objectForKey:@"FreeProduct"] boolValue] == YES)
		{
			[button setImage:[UIImage imageNamed:@"StorefrontFreeButton.png"] forState:UIControlStateNormal];
			[button addTarget:self action:@selector(downloadFreeProduct:) forControlEvents:UIControlEventTouchUpInside];
		}
		else if([(NSNumber*)[storeItem objectForKey:@"ViewOnly"] boolValue] == NO)
		{
			[button setImage:[UIImage imageNamed:@"StorefrontBuyButton.png"] forState:UIControlStateNormal];
			[button addTarget:self action:@selector(buyProduct:) forControlEvents:UIControlEventTouchUpInside];
		}

		
		
		if([(NSNumber*)[storeItem objectForKey:@"Installed"] boolValue]== NO && [(NSNumber*)[storeItem objectForKey:@"FreeProduct"] boolValue]== NO)
		{
			[currencyStyle setLocale:[storeItem objectForKey:@"PriceLocale"]];
			UILabel* priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0f,imageView.bounds.size.height-31.0f-5.0f,imageView.bounds.size.width-94.0f-20.0f-5.0f,26.0f)];
			[priceLabel setFont:[UIFont	fontWithName:@"Arial-BoldMT" size:18.0f]];
			[priceLabel setText:[NSString stringWithFormat:@"PRICE: %@",[currencyStyle stringFromNumber:[storeItem objectForKey:@"LocalizedPrice"]],nil]];
			[priceLabel setBackgroundColor:[UIColor clearColor]];
			[priceLabel setShadowColor:[UIColor grayColor]];
			[priceLabel setTextColor:[UIColor whiteColor]];
			[priceLabel setShadowOffset:CGSizeMake(1, 1)];
			[imageView addSubview:priceLabel];
			[priceLabel release];
		}
		
		[imageView addSubview:button];
		[contentView addSubview:imageView];
		[button release];
		[imageView release];
		currentItem++;
	}
	[contentView release];
	[currencyStyle release];
	[packScrollView setContentOffset:offset];
	[self removeStockingStoreOverlay];
}

-(void)downloadStarting
{
	[self showDownloadingOverlay];
}
-(void)downloadCompleted
{
	//[self showStorefrontItems];
	[self removeDownloadingOverlay];
	if(isShowing) [self populateStorefrontItems];
}
-(void)downloadFailed
{
	[self removeDownloadingOverlay];
}

- (void) buyProduct:(id)sender
{
	NSArray* storeItems = [storeManager storeItems];
	[storeManager purchaseItem:[[storeItems objectAtIndex:((UIButton*)sender).tag] objectForKey:@"ProductId"]];
}

- (void) updateProduct:(id)sender
{
	NSArray* storeItems = [storeManager storeItems];
	[storeManager updateItem:[[storeItems objectAtIndex:((UIButton*)sender).tag] objectForKey:@"ProductId"]];
}

- (void) downloadFreeProduct:(id)sender
{
	NSArray* storeItems = [storeManager storeItems];
	[storeManager downloadFreeItem:[[storeItems objectAtIndex:((UIButton*)sender).tag] objectForKey:@"ProductId"]];
}

- (void) populateStorefrontItems
{
	[self showStockingStoreOverlay];
	[storeManager loadStoreItemList];
	
}

- (void) removeStockingStoreOverlay
{
	[stockingStoreView removeFromSuperview];
	[transparentBackgroundView removeFromSuperview];
}

- (void) removeBackgroundView
{
	[packScrollView removeFromSuperview];
	[packScrollView release];
	packScrollView = nil;
	[backgroundView removeFromSuperview];
}

-(void)storeItemListDownloadCompleted
{
	[self showStorefrontItems];
	[self removeStockingStoreOverlay];
}

-(void)storeItemListDownloadFailed
{
	// TODO: Show alert, remove overlay, and close store
	[self removeStockingStoreOverlay];
	[self hide];
}

- (void) show
{
	// Make sure we can talk to the store before we bring up the UI
	Reachability* reachability = [Reachability reachabilityForInternetConnection];
	//[reachability setHostName:@"pinballmini.cogitu.com"];
	NetworkStatus remoteHostStatus = [reachability currentReachabilityStatus];
	if(remoteHostStatus == NotReachable)
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Could Not Connect" message:@"Unable to connect to the store. Please make sure you have an active internet connection or try again in a few moments."  delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}
	isShowing = YES;
	backgroundView.frame = OFFSCREEN_BOTTOM_POSITION;
	[[[[CCDirector sharedDirector] openGLView] window] addSubview:backgroundView];
	[UIView beginAnimations:@"storeSlideUp" context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:SLIDE_SPEED];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(populateStorefrontItems)];
	backgroundView.frame = ONSCREEN_POSITION;
	[UIView commitAnimations];
}

@end
