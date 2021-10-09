//
//  ImageResource.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/16/21.
//

#import "ImageResource.h"


@interface ImageResource()

@end

@implementation ImageResource

- (instancetype)initWithImage:(CIImage *)image duration:(CMTime)duration {
    if (self = [super init]) {
        self.image = image;
        self.status = ResourceStatusAvaliable;
        self.duration = duration;
        self.selectedTimeRange = CMTimeRangeMake(kCMTimeZero, duration);
    }
    return self;
}

#pragma mark - ResourceTrackInfoProvider
- (CIImage *)imageAtTime:(CMTime)time renderSize:(CGSize)renderSize {
    return self.image;
}

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone {
    ImageResource *resource = [[super class] allocWithZone:zone];
    resource.image = self.image;
    return resource;
}

@end
