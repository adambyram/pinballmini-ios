//
//  StoreManager.h
//  PinballMini
//
//  Created by Adam Byram on 2/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol StoreManagerStatusDelegate

@required
-(void)storeItemListDownloadCompleted;
-(void)storeItemListDownloadFailed;
-(void)downloadStarting;
-(void)downloadCompleted;
-(void)downloadFailed;
@end


@interface StoreManager : NSObject <SKProductsRequestDelegate,SKPaymentTransactionObserver> {
	NSArray* storeItems;
	NSArray* installedItems;
	id delegate;
	NSAutoreleasePool *pool;
	NSMutableArray* allStoreItems;
	BOOL purchasingItem;
	NSMutableArray* transactionQueue;
	BOOL currentlyProcessingTransaction;
}

@property (nonatomic, retain) NSArray* storeItems;
@property (nonatomic, retain) id delegate;

- (void) purchaseItem:(NSString*)productId;
- (void)setupOrLoadInstalledItems;
- (void) processAppStoreItems:(SKProductsResponse*)appStoreData;
-(void)downloadStarting;
-(void)downloadFailed;
- (NSString*) createEncodedString:(NSData*)data;
-(void)downloadCompleted;
-(void)downloadFailed;
- (void) restorePurchases;
- (void) updateItem:(NSString*)productId;
- (void) downloadFreeItem:(NSString*)productId;
- (void) loadStoreItemList;

@end
