//
//  ImageOverlayItem.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/16/21.
//

#import "ImageOverlayItem.h"
#import "ImageResource.h"

@implementation ImageOverlayItem

@synthesize duration;
@synthesize startTime;
@synthesize timeRange;

- (instancetype)initWithResource:(ImageResource *)resource {
    if (self = [super init]) {
        self.identifier = [[NSProcessInfo processInfo] globallyUniqueString];
        self.resource = resource;
        
        CGRect frame = CGRectMake(0, 0, resource.size.width, resource.size.height);
        self.videoConfiguration = [VideoConfiguration createDefaultConfiguration];
        self.videoConfiguration.contentMode = BaseContentModeAspectCustom;
        self.videoConfiguration.frame = frame;
        
        self.startTime = kCMTimeZero;
    }
    return self;
}


- (id)copyWithZone:(NSZone *)zone {
    ImageOverlayItem *item = [[self class] allocWithZone:zone];
    item.identifier = self.identifier;
    item.videoConfiguration = self.videoConfiguration.copy;
    item.startTime = self.startTime;
    return item;
}


#pragma mark - ImageCompositionProvider
- (CMTime)duration {
    return self.resource.scaledDuration;
}

- (CMTimeRange)timeRange {
    return CMTimeRangeMake(self.startTime, self.duration);
}


#pragma mark - VideoCompositionProvider
- (CIImage *)applyEffectToSourceImage:(CIImage *)sourceImage atTime:(CMTime)time renderSize:(CGSize)renderSize {
    CMTime relativeTime = CMTimeSubtract(time, self.timeRange.start);
    CIImage *image = [self.resource imageAtTime:relativeTime renderSize:renderSize];
    if (!image) {
        return sourceImage;
    }
    
    CIImage *finalImage = image;
    VideoConfigurationEffectInfo info = {time, renderSize, self.timeRange};
    finalImage = [self.videoConfiguration applyEffectToSourceImage:finalImage info:info];
    
    finalImage = [finalImage imageByCompositingOverImage:sourceImage];
    
    return finalImage;
}

@end
