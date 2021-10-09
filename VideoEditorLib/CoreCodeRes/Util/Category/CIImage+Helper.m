//
//  CIImage+Helper.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/10/21.
//

#import "CIImage+Helper.h"

@implementation CIImage (Helper)

- (CIImage *)flipYCoordinate {
    CGAffineTransform flipYTransform = CGAffineTransformMake(1, 0, 0, -1, 0, self.extent.origin.y*2+self.extent.size.height);
    return [self imageByApplyingTransform:flipYTransform];
}

- (CIImage *)applyAlpha:(CGFloat)alpha {
    CIFilter *filter = [CIFilter filterWithName:@"CIColorMatrix"];
    [filter setDefaults];
    [filter setValue:self forKey:kCIInputImageKey];
    CIVector *alphaVector = [[CIVector alloc] initWithX:0 Y:0 Z:0 W:alpha];
    [filter setValue:alphaVector forKey:@"inputAVector"];
    if (filter.outputImage) {
        return filter.outputImage;
    }
    return self;
}

@end
