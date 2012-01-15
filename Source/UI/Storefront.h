//
//  Storefront.h
//  PinballMini
//
//  Created by Adam Byram on 2/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StoreManager.h"

@interface Storefront : NSObject <StoreManagerStatusDelegate> {
	UIView* backgroundView;
	UIScrollView* packScrollView;
	UIView* stockingStoreView;
	UIView* downloadingContentView;
	UIView* transparentBackgroundView;
	StoreManager* storeManager;
	BOOL downloadOverlayActive;
	BOOL isShowing;
}

-(void)show;
- (void) removeStockingStoreOverlay;

@end
