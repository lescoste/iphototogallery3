//
//  SCNSBitmapImageRep+sizing.m
//  SCiPhotoToGallery
//
//  Created by Zachary Wily on Sun Nov 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "SCNSBitmapImageRep+sizing.h"

@implementation SCNSBitmapImageRep(Sizing)

- (SCNSBitmapImageRep *)representationWithSize:(NSSize)size
{
    NSRect rect = NSMakeRect(0, 0, size.width, size.height);
    NSImage *image = [[[NSImage alloc] initWithSize:size] autorelease];
    SCNSBitmapImageRep *outRep;
    [image lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
    [[NSGraphicsContext currentContext] setShouldAntialias:YES];
    [self drawInRect:rect];
    outRep = [[[SCNSBitmapImageRep alloc] initWithFocusedViewRect:rect] autorelease];
    [image unlockFocus];
    return outRep;
}

- (SCNSBitmapImageRep *)representationScaledTo:(NSSize)size
{
    NSSize originalSize = [self size];
    
    int old_x = [self pixelsWide];
    int old_y = [self pixelsHigh];
    int new_x = size.width;
    int new_y = size.height;
    int good_x;
    int good_y;
        
    float aspect = (float)old_x / (float)old_y;
        
    if (aspect >= 1) {
        good_x = new_x;
        good_y = new_x / aspect;
            
        if (good_y > new_y) {
            good_y = new_y;
            good_x = new_y * aspect;
        }
    }
    else {
        good_y = new_y;
        good_x = aspect * new_y;
            
        if (good_x > new_x) {
            good_x = new_x;
            good_y = new_x / aspect;
        }
    }
    // Don't go any bigger!
    if ((good_x > old_x) || (good_y > old_y)) {
        good_x = old_x;
        good_y = old_y;
    }
    NSLog(@"scaled %dx%d (aspect: %.2f) to %dx%d (aspect: %.2f) (target: %dx%d)\n",
            old_x, old_y, aspect, good_x, good_y, (float)good_x / (float)good_y, new_x, new_y);
    
    if (good_x != old_x) {
        return [self representationWithSize:NSMakeSize(good_x, good_y)];
    }
    else {
        return self;
    }
}

@end
