//
//  CachedImage.mm
//  PinballMini
//
//  Created by Adam Byram on 3/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CachedImage.h"


@implementation CachedImage

+(UIImage*)loadImage:(NSString*)imageUrl withVersion:(NSString*)ver
{
	NSMutableArray* cachedImages = [NSMutableArray arrayWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"CachedImageInfo.plist"]];
	
	if(cachedImages == nil)
	{
		cachedImages = [NSMutableArray array];
	}
	
	int imageNumber = -1;
	BOOL needsToCache = YES;
	int counter = 0;
	NSMutableDictionary* cachedImageReference;
	
	for(NSMutableDictionary* cachedImage in cachedImages)
	{
		if([(NSString*)[cachedImage objectForKey:@"ImageUrl"] compare:imageUrl] == NSOrderedSame)
		{
			imageNumber = counter;
			cachedImageReference = cachedImage;
			if([(NSString*)[cachedImage objectForKey:@"ImageVersion"] compare:ver] == NSOrderedSame)
			{
				needsToCache = NO;
			}
			else {
				needsToCache = YES;
			}

			break;
		}
		counter++;
	}
	
	NSData* imageData = nil;
	
	if(imageNumber == -1)
	{
		// No cache at all, download and store
		imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
		imageNumber = [cachedImages count];
		cachedImageReference = [NSMutableDictionary dictionary];
		[cachedImageReference setObject:ver forKey:@"ImageVersion"];	
		[cachedImageReference setObject:imageUrl forKey:@"ImageUrl"];
		[cachedImages addObject:cachedImageReference];
		[imageData writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"CachedImage_%i.png",imageNumber,nil]] atomically:YES];
	}
	else if (needsToCache == YES)
	{
		// Have cache, but need to redownload new version
		imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
		imageNumber = [cachedImages count];
		[cachedImageReference setObject:ver forKey:@"ImageVersion"];
		[cachedImages addObject:cachedImageReference];
		[imageData writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"CachedImage_%i.png",imageNumber,nil]] atomically:YES];
	}
	else {
		// Have cache and it's fresh
		imageData = [NSData dataWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"CachedImage_%i.png",imageNumber,nil]]];
	}
	
	[cachedImages writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"CachedImageInfo.plist"] atomically:YES];		 
	return [UIImage imageWithData:imageData];
}

@end
