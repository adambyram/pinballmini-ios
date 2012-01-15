//
//  CachedImage.h
//  PinballMini
//
//  Created by Adam Byram on 3/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CachedImage : NSObject {

	
}

+(UIImage*)loadImage:(NSString*)imageUrl  withVersion:(NSString*)version;


@end
