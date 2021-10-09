//
//  TrackConfiguration.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/9/21.
//

#import "VideoConfiguration.h"
#import "TransformConvertHelper.h"
#import "CIImage+Helper.h"

@implementation VideoConfiguration


+ (instancetype)createDefaultConfiguration {
    return [[self alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
        _contentMode = BaseContentModeAspectFit;
        _transform = CGAffineTransformIdentity;
        _opacity = 1.0;
        _configurations = [NSMutableArray array];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    VideoConfiguration *videoConfiguration = [[self class] allocWithZone:zone];
    videoConfiguration.contentMode = self.contentMode;
    videoConfiguration.frame = self.frame;
    videoConfiguration.transform = self.transform;
    videoConfiguration.opacity = self.opacity;
    
    NSMutableArray *configurations = [[NSMutableArray alloc] init];
    for (id<VideoConfigurationProtocol> configure in self.configurations) {
        [configurations addObject:[configure copyWithZone:zone]];
    }
    videoConfiguration.configurations = configurations;
    
    return videoConfiguration;
}

#pragma mark - VideoConfigurationProtocol
- (CIImage *)applyEffectToSourceImage:(CIImage *)sourceImg info:(VideoConfigurationEffectInfo)info {
    CIImage *finalImage = sourceImg;
    
    if (!CGAffineTransformEqualToTransform(self.transform, CGAffineTransformIdentity)) {
        CGAffineTransform transform = CGAffineTransformIdentity;
        CGAffineTransform tempTransform = CGAffineTransformMakeTranslation(-(finalImage.extent.origin.x + finalImage.extent.size.width/2), -(finalImage.extent.origin.y + finalImage.extent.size.height/2));
        transform = CGAffineTransformConcat(transform, tempTransform);
        transform = CGAffineTransformConcat(transform, self.transform);
        transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation((finalImage.extent.origin.x + finalImage.extent.size.width/2), (finalImage.extent.origin.y + finalImage.extent.size.height/2)));
        finalImage = [finalImage imageByApplyingTransform:transform];
    }
    
    CGRect frame = self.frame;
    if (CGRectEqualToRect(frame, CGRectZero)) {
        frame = CGRectMake(0, 0, info.renderSize.width, info.renderSize.height);
    }
    
    switch (self.contentMode) {
        case BaseContentModeAspectFit: {
            CGAffineTransform transform = [TransformConvertHelper transformBySourceRect:finalImage.extent aspectFitInRect:frame];
            finalImage = [[finalImage imageByApplyingTransform:transform] imageByCroppingToRect:frame];
        }
            break;
        case BaseContentModeAspectFill: {
            CGAffineTransform transform = [TransformConvertHelper transformBySourceRect:finalImage.extent aspectFillInRect:frame];
            finalImage = [[finalImage imageByApplyingTransform:transform] imageByCroppingToRect:frame];
        }
            break;
        
        case BaseContentModeAspectCustom: {
            CGAffineTransform transform = CGAffineTransformMakeScale(frame.size.width/sourceImg.extent.size.width, frame.size.height/sourceImg.extent.size.height);
            CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(frame.origin.x, frame.origin.y);
            transform = CGAffineTransformConcat(transform, translateTransform);
            finalImage = [finalImage imageByApplyingTransform:transform];
        }
            break;
        default:
            break;
    }
    
    finalImage = [finalImage applyAlpha:self.opacity];
    
    for (id<VideoConfigurationProtocol> videoConfiguration in self.configurations) {
        finalImage = [videoConfiguration applyEffectToSourceImage:finalImage info:info];
    }
    
    return finalImage;
}

@end
