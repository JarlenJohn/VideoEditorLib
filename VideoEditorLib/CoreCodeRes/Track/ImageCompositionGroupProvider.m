//
//  ImageCompositionGroupProvider.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/16/21.
//

#import "ImageCompositionGroupProvider.h"

@implementation ImageCompositionGroupProvider


- (instancetype)init {
    if (self = [super init]) {
        _imageCompositionProviders = [[NSArray alloc] init];
    }
    return self;
}

- (CIImage *)applyEffectToSourceImage:(CIImage *)sourceImage atTime:(CMTime)time renderSize:(CGSize)renderSize {
    for (id<ImageCompositionProvider> provider in self.imageCompositionProviders) {
        if (CMTimeRangeContainsTime(provider.timeRange, time)) {
            sourceImage = [provider applyEffectToSourceImage:sourceImage atTime:time renderSize:renderSize];
        }
    }
    
    if (self.passingThroughVideoCompositionProvider) {
        sourceImage = [self.passingThroughVideoCompositionProvider applyEffectToSourceImage:sourceImage atTime:time renderSize:renderSize];
    }
    return sourceImage;
}

@end
