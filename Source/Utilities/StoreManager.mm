//
//  StoreManager.mm
//  PinballMini
//
//  Created by Adam Byram on 2/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "StoreManager.h"
#import "MultipartForm.h"
#import "ZipArchive.h"
#import "CachedImage.h"
#import "PinballMiniAppDelegate.h"
#import "Reachability.h"


@implementation StoreManager

@synthesize storeItems;
@synthesize delegate;

-(id)init
{
	if(self = [super init])
	{
		storeItems = nil;
		pool = nil;
		allStoreItems = nil;
		installedItems = nil;
		transactionQueue = [[NSMutableArray alloc] init];
		currentlyProcessingTransaction = NO;
		[self setupOrLoadInstalledItems];		
	}
	return self;
}

-(void)dealloc
{
	[transactionQueue release];
	[storeItems release];
	[pool release];
	[allStoreItems release];
	[installedItems release];
	[super dealloc];
}

- (void)setupOrLoadInstalledItems
{
	//KeychainItemWrapper* installedItemsWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"InstalledItems" accessGroup:nil];
	//installedItems = [installedItemsWrapper objectForKey:@"InstalledItemData"];
	NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
	
	if(![[NSFileManager defaultManager] fileExistsAtPath:[documentsPath stringByAppendingPathComponent:@"Configuration"]])
	{
		NSError* error;
		[[NSFileManager defaultManager] createDirectoryAtPath:[documentsPath stringByAppendingPathComponent:@"Configuration"] withIntermediateDirectories:NO attributes:nil error:&error];
	}
	
	if([[NSFileManager defaultManager] fileExistsAtPath:[documentsPath stringByAppendingPathComponent:@"Configuration/InstalledProducts.plist"]])
	{
		installedItems = [[NSArray arrayWithContentsOfFile:[documentsPath stringByAppendingPathComponent:@"Configuration/InstalledProducts.plist"]] retain];
	}
	if(installedItems == nil)
	{
		installedItems = [[NSArray alloc] init];
	}
	//[installedItemsWrapper release];
}

- (void)saveInstalledItemsToKeychain
{
	//KeychainItemWrapper* installedItemsWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"InstalledItems" accessGroup:nil];
	//[installedItemsWrapper setObject:installedItems forKey:@"InstalledItemData"];
	//[installedItemsWrapper release];
	NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
	if(![installedItems writeToFile:[documentsPath stringByAppendingPathComponent:@"Configuration/InstalledProducts.plist"] atomically:YES])
	{
		NSLog(@"Write to file failed.");
	}
}

-(void)updateInstalledItemsWithPurchaseForProductId:(NSString*)productId andReceipt:(NSData*)receipt
{
	NSMutableDictionary* installedItem = nil;
	NSMutableDictionary* storeItem = nil;
	int storeItemPosition = 0;
	int installedItemPosition = 0;
	
	
	if(storeItems == nil)
	{
		allStoreItems = [[NSMutableArray arrayWithContentsOfURL:[NSURL URLWithString:@"http://pinballmini.cogitu.com/shop/products/"]] retain];
		//NSMutableSet* itemsToRequest = [[NSMutableSet alloc] init];
		//NSMutableArray* currentlyInstalledProducts = [[NSMutableArray alloc] init];
		
		for(id storeItem in allStoreItems)
		{
				[storeItem setObject:[NSNumber numberWithBool:NO] forKey:@"Installed"];
				[storeItem setObject:[NSNumber numberWithBool:NO] forKey:@"UpgradeNeeded"];			
		}
		storeItems = allStoreItems;
	}
	
	// Find the storefront item we need
	for(NSDictionary* currentStoreItem in storeItems)
	{
		if([(NSString*)[currentStoreItem objectForKey:@"ProductId"] compare:productId] == NSOrderedSame)
		{
			storeItem = [currentStoreItem mutableCopy];
			break;
		}
		storeItemPosition++;
	}
		if(storeItem == nil)
		{
			NSLog(@"Error...store item not found.");
		}
	
	
	
	
	
	// Update installed items
	for(NSDictionary* currentInstalledItem in installedItems)
	{
		if([(NSString*)[currentInstalledItem objectForKey:@"ProductId"] compare:productId] == NSOrderedSame)
		{
			installedItem = [currentInstalledItem mutableCopy];
			break;
		}
		installedItemPosition++;
	}
	if(installedItem == nil)
	{
		installedItemPosition = -1;
		installedItem = [[NSMutableDictionary alloc] init];
		[installedItem setObject:productId forKey:@"ProductId"];
	}
	// We can get a nil receipt if we're getting a free product
	if(receipt != nil) [installedItem setObject:receipt forKey:@"Receipt"];
	[installedItem setObject:[storeItem objectForKey:@"ProductVersion"] forKey:@"ProductVersion"];

	
	
	// Update storefront items
	[storeItem setObject:[NSNumber numberWithBool:YES] forKey:@"Installed"];
	[storeItem setObject:[NSNumber numberWithBool:NO] forKey:@"UpgradeNeeded"];
	
	
	// Replace live data with updated data
	NSMutableArray* newItemArray = [[NSMutableArray alloc] initWithArray:installedItems];
	if(installedItemPosition != -1)
	{
		[newItemArray removeObjectAtIndex:installedItemPosition];
		[newItemArray insertObject:installedItem atIndex:installedItemPosition];
	}
	else
	{
		[newItemArray addObject:installedItem];
	}
	[installedItems release];
	installedItems = newItemArray;
	
	NSMutableArray* newStoreItemArray = [[NSMutableArray alloc] initWithArray:storeItems];
	[newStoreItemArray removeObjectAtIndex:storeItemPosition];
	[newStoreItemArray insertObject:storeItem atIndex:storeItemPosition];
	[storeItems release];
	storeItems = newStoreItemArray;
	
	[installedItem release];
	[storeItem release];
	[self saveInstalledItemsToKeychain];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	[self processAppStoreItems:response]; 
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
	if([request isMemberOfClass:[SKProductsRequest class]])
	{
		[self performSelectorOnMainThread:@selector(storeItemListFailed) withObject:nil waitUntilDone:NO];
	}
}

-(BOOL)installProductForTransactionWithProductId:(NSString*)productId andReceipt:(NSData*)receipt andData:(NSData*)productData
{
	NSError* error = nil;
	NSString* baseDocumentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
	NSString* downloadPath = [baseDocumentPath stringByAppendingPathComponent:productId];
	
	// Write the downloaded data to disk
	if(![productData writeToFile:[baseDocumentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",productId,nil]] atomically:NO])
	{
		NSLog(@"Product data not written to disk.");
		return NO;
	}
	
	// Decompress the data
	ZipArchive* archive = [[ZipArchive alloc] init];
	BOOL openedFileToDecompress = [archive UnzipOpenFile:[baseDocumentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",productId,nil]] Password:nil];
	if(!openedFileToDecompress)
	{
		// Couldn't open the file to decompress it
		[archive release];
		return NO;
	}
	
	
	// Remove any old folders with this name if they exist (in case a download was bad)
	if([[NSFileManager defaultManager] fileExistsAtPath:downloadPath])
	{
		[[NSFileManager defaultManager] removeItemAtPath:downloadPath error:&error];
		NSLog(@"Error: %@",error);
		
		if(error != nil) 
		{
			[archive release];
			return NO;
		}
	}
	
	if([archive UnzipFileTo:downloadPath overWrite:YES])
	{
		[[NSFileManager defaultManager] removeItemAtPath:[baseDocumentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",productId,nil]] error:&error];
		NSLog(@"Error: %@", error);
		if(error != nil) 
		{
			[archive release];
			return NO;
		}
	}
	else {
		// Unable to unzip the file for some reason
		[archive release];
		return NO;
	}
	[archive release];
	
	
	NSArray* directoryContents = [[NSFileManager defaultManager] directoryContentsAtPath:downloadPath];
	NSMutableArray* newBoards = [[NSMutableArray alloc] init];

	for(NSString* file in directoryContents)
	{
		// Do NOT copy this file to the boards
		if([file compare:@"__MACOSX"] == NSOrderedSame) continue;
		NSString* fullFilePath = [downloadPath stringByAppendingPathComponent:file];
		BOOL isDirectory = NO;
		if([[NSFileManager defaultManager] fileExistsAtPath:fullFilePath isDirectory:&isDirectory] && isDirectory)
		{
			
			
			if([[NSFileManager defaultManager] fileExistsAtPath:[[baseDocumentPath stringByAppendingPathComponent:@"Boards/"] stringByAppendingPathComponent:file]])
			{
				[[NSFileManager defaultManager] removeItemAtPath:[[baseDocumentPath stringByAppendingPathComponent:@"Boards/"] stringByAppendingPathComponent:file] error:&error];
				if(error != nil)
				{
					NSLog(@"%@",error);
					
					if(error != nil)
					{
						[newBoards release];
						return NO;
					}
				}
			}
			
			[[NSFileManager defaultManager] copyItemAtPath:fullFilePath toPath:[[baseDocumentPath stringByAppendingPathComponent:@"Boards/"] stringByAppendingPathComponent:file] error:&error];
			if(error != nil)
			{
				NSLog(@"%@",error);
				if(error != nil) 
				{
					[newBoards release];
					return NO;
				}
			}
			
			[newBoards addObject:[[NSDictionary dictionaryWithContentsOfFile:[fullFilePath stringByAppendingPathComponent:@"BoardInfo.plist"]] objectForKey:@"BoardId"]];
			[[NSFileManager defaultManager] removeItemAtPath:fullFilePath error:&error];
			if(error != nil)
			{
				NSLog(@"%@",error);
				if(error != nil) 
				{
					[newBoards release];
					return NO;
				}
			}
		}
	}
	[[NSFileManager defaultManager] removeItemAtPath:downloadPath error:&error];
	
	NSMutableArray* installedBoardArray = [NSMutableArray arrayWithContentsOfFile:[baseDocumentPath stringByAppendingPathComponent:@"Configuration/InstalledBoards.plist"]];
	for(NSString* board in newBoards)
	{
		BOOL alreadyAdded = NO;
		for(NSDictionary* dictionary in installedBoardArray)
		{
			if([(NSString*)[dictionary objectForKey:@"BoardId"] compare:board] == NSOrderedSame)
			{
				alreadyAdded = YES;
				break;
			}
		}
		if(!alreadyAdded)
		{
			[installedBoardArray addObject:[NSDictionary dictionaryWithObject:board forKey:@"BoardId"]];
		}
	}
	
	[installedBoardArray writeToFile:[baseDocumentPath stringByAppendingPathComponent:@"Configuration/InstalledBoards.plist"] atomically:YES];
	
	// Update the installed items data
	[self updateInstalledItemsWithPurchaseForProductId:productId andReceipt:receipt];
	
	NSLog(@"Installation of board completed.");
	[newBoards release];
	return YES;
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
	
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	for(SKPaymentTransaction* transaction in transactions)
	{
	if(transaction.transactionState == SKPaymentTransactionStatePurchased)
	{
		NSLog(@"Completed purchase.");
		[transactionQueue addObject:transaction];
		[NSThread detachNewThreadSelector:@selector(threadStartVerifyAndDownloadItem) toTarget:self withObject:nil];
	}
	else if(transaction.transactionState == SKPaymentTransactionStateRestored)
	{
		[self downloadStarting];
		[transactionQueue addObject:transaction];
		[NSThread detachNewThreadSelector:@selector(threadStartVerifyAndDownloadItem) toTarget:self withObject:nil];
	}
	else if(transaction.transactionState == SKPaymentTransactionStateFailed)
	{
		// TODO
		[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
		[self downloadFailed];
		NSLog(@"Failed.");
	}
	}
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
}

-(void)threadStartVerifyAndDownloadItem
{
	Reachability* reachability = [Reachability reachabilityForInternetConnection];
	//[reachability setHostName:@"pinballmini.cogitu.com"];
	NetworkStatus remoteHostStatus = [reachability currentReachabilityStatus];
	if(remoteHostStatus == NotReachable)
	{
		// If we can't download anything, just stop
		[self performSelectorOnMainThread:@selector(downloadCompleted) withObject:nil waitUntilDone:NO];
		return;
	}
	
	if(currentlyProcessingTransaction) return;
	currentlyProcessingTransaction = YES;
	pool = [[NSAutoreleasePool alloc] init];
	
	while([transactionQueue count] > 0)
	{
		id item = [transactionQueue objectAtIndex:0];
		SKPaymentTransaction* transaction = nil;
		BOOL itemIsTransaction = [item isMemberOfClass:[SKPaymentTransaction class]];
		if(itemIsTransaction)
		{
			transaction = (SKPaymentTransaction*)item;
		}
	
		[transactionQueue objectAtIndex:0];
		NSString* receiptString = (itemIsTransaction)?[self createEncodedString:transaction.transactionReceipt]:nil;
		
		NSString* requestType = (itemIsTransaction)?@"purchase":(NSString*)[item objectForKey:@"RequestType"];
	

	MultipartForm* multipartForm = [[MultipartForm alloc] initWithURL:[NSURL URLWithString:@"http://pinballmini.cogitu.com/shop/download/"]];
	if(itemIsTransaction) [multipartForm addFormField:@"receipt" withStringData:receiptString];
	[multipartForm addFormField:@"productId" withStringData:(itemIsTransaction)?transaction.payment.productIdentifier:(NSString*)[item objectForKey:@"ProductId"]];
	[multipartForm addFormField:@"deviceId" withStringData:[[UIDevice currentDevice] uniqueIdentifier]];
	[multipartForm addFormField:@"deviceModel" withStringData:[[UIDevice currentDevice] model]];
	[multipartForm addFormField:@"deviceOSVersion" withStringData:[[UIDevice currentDevice] systemVersion]];
	[multipartForm addFormField:@"applicationVersion" withStringData:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
	[multipartForm addFormField:@"requestType" withStringData:requestType];
	[multipartForm addFormField:@"applicationId" withStringData:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]];
		
	NSURLRequest* request = [multipartForm mpfRequest];
	[multipartForm release];
	NSHTTPURLResponse* response;
	NSError* error;
	NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		NSLog(@"%@",[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
		NSLog(@"Status: %i",[response statusCode]);
	if([response statusCode] != 200)
	{
		// There was a problem downloading the data - so mark the download as failed
		[self performSelectorOnMainThread:@selector(downloadFailedForTransaction:) withObject:transaction waitUntilDone:NO];
	}
	else 
	{
		if([self installProductForTransactionWithProductId:(itemIsTransaction)?transaction.payment.productIdentifier:(NSString*)[item objectForKey:@"ProductId"] andReceipt:(itemIsTransaction)?transaction.transactionReceipt:nil andData:data])
		{
			[self performSelectorOnMainThread:@selector(downloadCompletedForTransaction:) withObject:transaction waitUntilDone:NO];
		}
		else 
		{
			// TODO - this really should be installation failed since the download did happen
			[self performSelectorOnMainThread:@selector(downloadFailedForTransaction:) withObject:transaction waitUntilDone:NO];
		}

	}
		[transactionQueue removeObject:item];
	}

	[pool drain];
	currentlyProcessingTransaction = NO;
}

-(void) downloadCompletedForTransaction:(SKPaymentTransaction*)transaction
{
	NSLog(@"Data downloaded.");
	// TODO: Is this the right place to reload the board display?
	[[(PinballMiniAppDelegate*)[[UIApplication sharedApplication] delegate] mainMenu] reloadBoardDisplay];
	if(transaction != nil) [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	[self downloadCompleted];
}

-(void) downloadFailedForTransaction:(SKPaymentTransaction*)transaction
{
	NSLog(@"Data download failed.");
	// TEST CODE
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Download Failed" message:@"The download failed for an unknown reason.  If you are attempting to purchase an item, the download will re-try automatically the next time you launch this app.  Otherwise, please wait a few minutes and try your free download or update again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView autorelease];
	// TEST CODE END
	[self downloadFailed];
}

- (void) loadStoreItemList
{
	//[self threadStartPopulateStoreItems];
	[NSThread detachNewThreadSelector:@selector(threadStartPopulateStoreItems) toTarget:self withObject:nil];
}

- (void) storeItemListLoaded
{
	if([[self delegate] respondsToSelector:@selector(storeItemListDownloadCompleted)])
	{
		[[self delegate] storeItemListDownloadCompleted];
	}
}

- (void) storeItemListFailed
{
	if([[self delegate] respondsToSelector:@selector(storeItemListDownloadFailed)])
	{
		[[self delegate] storeItemListDownloadFailed];
	}
}

-(void)downloadStarting
{
	if([[self delegate] respondsToSelector:@selector(downloadStarting)])
	{
		[[self delegate] downloadStarting];
	}
}

-(void)downloadCompleted
{
	//if([transactionQueue count] > 0) 
	//{
		// Don't send the completed message until all downloads are done, so try again in a second
	//	[NSRunLoop cancelPreviousPerformRequestsWithTarget:self selector:@selector(downloadCompleted) object:nil];
	//	[self performSelector:@selector(downloadCompleted) withObject:nil afterDelay:1.0f];
	//}
	purchasingItem = NO;
	if([[self delegate] respondsToSelector:@selector(downloadCompleted)])
	{
		[[self delegate] downloadCompleted];
	}
}

-(void)downloadFailed
{
	purchasingItem = NO;
	if([[self delegate] respondsToSelector:@selector(downloadFailed)])
	{
		[[self delegate] downloadFailed];
	}
}

- (void) purchaseItem:(NSString*)productId
{
	if(purchasingItem == NO)
	{
	if([SKPaymentQueue canMakePayments])
	{
		// We're good to go - let them purchase
		purchasingItem = YES;
		SKPayment* payment = [SKPayment paymentWithProductIdentifier:productId];
		[[SKPaymentQueue defaultQueue] addPayment:payment];
		[self downloadStarting];
	}
	else
	{
		// Can't purchase
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Purchases Disabled" message:@"Sorry, but you have the in-app purchase feature disabled. Please enable it and then try your purchase again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
		[alertView autorelease];
	}
	}
}

- (void) downloadFreeItem:(NSString*)productId
{
	[self downloadStarting];
	NSDictionary* freeItem = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:productId,@"free",nil] forKeys:[NSArray arrayWithObjects:@"ProductId",@"RequestType",nil]];
	[transactionQueue addObject:freeItem];
	[NSThread detachNewThreadSelector:@selector(threadStartVerifyAndDownloadItem) toTarget:self withObject:nil];
	[freeItem release];
}

- (void) updateItem:(NSString*)productId
{
	[self downloadStarting];
	NSData* receipt = nil;
	
	// Make sure we look up our receipt (we may not have one IF this was a free item when purchased originally)
	for(id installedItem in installedItems)
	{
		if([(NSString*)[installedItem objectForKey:@"ProductId"] compare:productId] == NSOrderedSame)
		{
			receipt = [installedItem objectForKey:@"Receipt"];
			break;
		}
	}
	
	NSDictionary* updateItem = nil;
	if(receipt != nil)
	{
		updateItem = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:productId,receipt,@"update",nil] forKeys:[NSArray arrayWithObjects:@"ProductId",@"Receipt",@"RequestType",nil]];
	}
	else {
		updateItem = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:productId,@"update",nil] forKeys:[NSArray arrayWithObjects:@"ProductId",@"RequestType",nil]];
	}

	[transactionQueue addObject:updateItem];
	[NSThread detachNewThreadSelector:@selector(threadStartVerifyAndDownloadItem) toTarget:self withObject:nil];
	[updateItem release];
}

- (void) restorePurchases
{
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void) processAppStoreItems:(SKProductsResponse*)appStoreData
{
	pool = [[NSAutoreleasePool alloc] init]; 
	NSMutableArray* currentlyInstalledProducts = [[NSMutableArray alloc] init];
	for(id installedItem in installedItems)
	{
		[currentlyInstalledProducts addObject:[installedItem objectForKey:@"ProductId"]];
	}
	NSArray* applicationVersionComponents = [(NSString*)[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] componentsSeparatedByString:@"."];
	int applicationMajorVersion = [[applicationVersionComponents objectAtIndex:0] intValue];
	int applicationMinorVersion = [[applicationVersionComponents objectAtIndex:1] intValue];
	int applicationRevisionVersion = [[applicationVersionComponents objectAtIndex:2] intValue];
	NSMutableArray* itemsToRemove = [[NSMutableArray alloc] init];
	for(id storeItem in allStoreItems)
	{
		[storeItem setObject:[NSNumber numberWithBool:NO] forKey:@"ViewOnly"];
		NSArray* storeItemRequiredVersion = [(NSString*)[storeItem objectForKey:@"RequiredAppVersion"] componentsSeparatedByString:@"."];
		int requiredMajorVersion = [[storeItemRequiredVersion objectAtIndex:0] intValue];
		int requiredMinorVersion = [[storeItemRequiredVersion objectAtIndex:1] intValue];
		int requiredRevisionVersion = [[storeItemRequiredVersion objectAtIndex:2] intValue];
		if(requiredMajorVersion > applicationMajorVersion || (requiredMajorVersion == applicationMajorVersion && requiredMinorVersion > applicationMinorVersion) || (requiredMajorVersion == applicationMajorVersion && requiredMinorVersion == applicationMinorVersion && requiredRevisionVersion > applicationRevisionVersion))
		{
			// This product requires a newer version of the application, so discard it
			[itemsToRemove addObject:storeItem];
			continue;
		}
		// If we don't have the original pack installed, then discard everything except the original pack data
		if(!([currentlyInstalledProducts containsObject:@"com.cogitu.pinballmini.originalpack"] || [currentlyInstalledProducts containsObject:@"com.cogitu.pinballminilite.originalpack"]))
		{
			BOOL isOriginalPack = [(NSString*)[storeItem objectForKey:@"ProductId"] compare:@"com.cogitu.pinballmini.originalpack"] == NSOrderedSame;
			isOriginalPack |= [(NSString*)[storeItem objectForKey:@"ProductId"] compare:@"com.cogitu.pinballminilite.originalpack"] == NSOrderedSame;
			if(!isOriginalPack) 
			{
				// The user hasn't unlocked the original pack yet, so nothing else can be downloaded yet
				[storeItem setObject:[NSNumber numberWithBool:YES] forKey:@"ViewOnly"];
			}
		}
		
		// Grab the product details from Apple (mainly price is what we care about right now)
		if([(NSNumber*)[storeItem objectForKey:@"FreeProduct"] boolValue] == NO && [(NSNumber*)[storeItem objectForKey:@"Installed"] boolValue] == NO)
		{
			// Only look for Apple info if the file is a paid download...if the info can't be found, remove this item since it
			// isn't live in the store yet.
			BOOL foundProduct = NO;
			for(SKProduct* appStoreProduct in appStoreData.products)
			{
				if([appStoreProduct.productIdentifier compare:[storeItem objectForKey:@"ProductId"]] == NSOrderedSame)
				{
					[storeItem setObject:appStoreProduct.price forKey:@"LocalizedPrice"];
					[storeItem setObject:appStoreProduct.priceLocale forKey:@"PriceLocale"];
					foundProduct = YES;
					break;
				}
			}
			if(!foundProduct)
			{
				// We didn't find this product in the app store list of valid products, so remove it (can't purchase it)
				[itemsToRemove addObject:storeItem];
				continue;
			}
		}
		
		// If we didn't throw it out by now, we'll need the product images
		//[storeItem setObject:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[storeItem objectForKey:@"UnpurchasedProductImageUrl"]]]] forKey:@"UnpurchasedProductImage"];
		//[storeItem setObject:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[storeItem objectForKey:@"PurchasedProductImageUrl"]]]] forKey:@"PurchasedProductImage"];
		[storeItem setObject:[CachedImage loadImage:[storeItem objectForKey:@"PurchasedProductImageUrl"] withVersion:[storeItem objectForKey:@"PurchasedProductImageUrlVersion"]] forKey:@"PurchasedProductImage"];
		[storeItem setObject:[CachedImage loadImage:[storeItem objectForKey:@"UnpurchasedProductImageUrl"] withVersion:[storeItem objectForKey:@"UnpurchasedProductImageUrlVersion"]] forKey:@"UnpurchasedProductImage"];
	}
	
	// Remove objects that aren't for sale yet (App Store side) or require a higher version of the app
	for(id storeItemToRemove in itemsToRemove)
	{
		[allStoreItems removeObject:storeItemToRemove];
	}
	[itemsToRemove release];
	
	
	[storeItems release];
	storeItems = [allStoreItems copy];
	[allStoreItems release];
	
	[self performSelectorOnMainThread:@selector(storeItemListLoaded) withObject:nil waitUntilDone:NO];
	[pool drain];	
	//pool = nil;
}


- (void) threadStartPopulateStoreItems
{
	
	pool = [[NSAutoreleasePool alloc] init]; 
	allStoreItems = [[NSMutableArray arrayWithContentsOfURL:[NSURL URLWithString:@"http://pinballmini.cogitu.com/shop/products/"]] retain];
	NSMutableSet* itemsToRequest = [[NSMutableSet alloc] init];
	NSMutableArray* currentlyInstalledProducts = [[NSMutableArray alloc] init];
	for(id installedItem in installedItems)
	{
		[currentlyInstalledProducts addObject:[installedItem objectForKey:@"ProductId"]];
	}
	
	for(id storeItem in allStoreItems)
	{
		if([(NSNumber*)[storeItem objectForKey:@"FreeProduct"] boolValue] == NO && ![currentlyInstalledProducts containsObject:[storeItem objectForKey:@"ProductId"]])
		{
			[itemsToRequest addObject:[storeItem objectForKey:@"ProductId"]];
		}
		if([currentlyInstalledProducts containsObject:[storeItem objectForKey:@"ProductId"]])
		{
			// If the stoe items are currently installed, we'll go ahead and set the Installed and UpToDate flags now
			for(id installedItem in installedItems)
			{
				// Find the installed product record
				if([(NSString*)[installedItem objectForKey:@"ProductId"] compare:[storeItem objectForKey:@"ProductId"]] == NSOrderedSame)
				{
					[storeItem setObject:[NSNumber numberWithBool:YES] forKey:@"Installed"];
					// If the installed version is lower than the store version, we need to update
					if([[installedItem objectForKey:@"ProductVersion"] intValue] < [[storeItem objectForKey:@"ProductVersion"] intValue])
					{
						[storeItem setObject:[NSNumber numberWithBool:YES] forKey:@"UpgradeNeeded"];
					}
					else 
					{
						[storeItem setObject:[NSNumber numberWithBool:NO] forKey:@"UpgradeNeeded"];
					}

				}
			}
		}
		else 
		{
			// For completeness
			[storeItem setObject:[NSNumber numberWithBool:NO] forKey:@"Installed"];
			[storeItem setObject:[NSNumber numberWithBool:NO] forKey:@"UpgradeNeeded"];
		}

	}
	
	[currentlyInstalledProducts release];
	SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:itemsToRequest];
	[request setDelegate:self];
	[request start];
	[itemsToRequest release];
	[pool drain];
}

// Base64 Encoder
- (NSString*) createEncodedString:(NSData*)data
{
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
	
    const int size = ((data.length + 2)/3)*4;
    uint8_t output[size];
	
    const uint8_t* input = (const uint8_t*)[data bytes];
    for (int i = 0; i < data.length; i += 3)
    {
        int value = 0;
        for (int j = i; j < (i + 3); j++)
        {
            value <<= 8;
            if (j < data.length)
                value |= (0xFF & input[j]);
        }
		
        const int index = (i / 3) * 4;
        output[index + 0] =  table[(value >> 18) & 0x3F];
        output[index + 1] =  table[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < data.length ? table[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < data.length ? table[(value >> 0)  & 0x3F] : '=';
    }    
	
    return  [[NSString alloc] initWithBytes:output length:size encoding:NSASCIIStringEncoding];
}

@end
