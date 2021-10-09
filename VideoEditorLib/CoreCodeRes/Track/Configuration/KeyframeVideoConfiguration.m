//
//  KeyframeVideoConfiguration.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/17/21.
//

#import "KeyframeVideoConfiguration.h"


@interface KeyframeVideoConfiguration()

@property (nonatomic, strong) NSMutableArray *keyframes;
@end


@implementation KeyframeVideoConfiguration

- (instancetype)init {
    if (self = [super init]) {
        _keyframes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)insert:(Keyframe *)keyframe {
    NSUInteger index = self.keyframes.count;
    for (Keyframe *frame in self.keyframes) {
        if (CMTIME_COMPARE_INLINE(frame.time, >, keyframe.time)) {
            index = [self.keyframes indexOfObject:frame];
            break;
        }
    }
    
    [self.keyframes insertObject:keyframe atIndex:index];
}

- (void)remove:(Keyframe *)keyframe {
    [self.keyframes removeObject:keyframe];
}

- (void)removeAllKeyframes {
    [self.keyframes removeAllObjects];
}

- (void)removeKeyframesInTimeRange:(CMTimeRange)timeRange {
    NSMutableArray *deleteArr = [[NSMutableArray alloc] init];
    for (Keyframe *keyframe in self.keyframes) {
        if (CMTimeRangeContainsTime(timeRange, keyframe.time)) {
            [deleteArr addObject:keyframe];
        }
    }
    [self.keyframes removeObjectsInArray:deleteArr];
}

- (id)copyWithZone:(NSZone *)zone {
    KeyframeVideoConfiguration *configuration = [[self class] allocWithZone:zone];
    NSMutableArray *copiedArr = [[NSMutableArray alloc] init];
    for (Keyframe *keyframe in self.keyframes) {
        [copiedArr addObject:[keyframe copyWithZone:zone]];
    }
    configuration.keyframes = copiedArr;
    return configuration;
}


#pragma mark - VideoConfigurationProtocol
- (CIImage *)applyEffectToSourceImage:(CIImage *)sourceImg info:(VideoConfigurationEffectInfo)info {
    CIImage *finalImage = sourceImg;
    
    if (self.keyframes.count > 0) {
        NSUInteger toIndex = 0;
        for (Keyframe *keyframe in self.keyframes) {
            CMTime interTime = CMTimeSubtract(info.time, info.timeRange.start);
            if (CMTIME_COMPARE_INLINE(interTime, <=, keyframe.time)) {
                toIndex = [self.keyframes indexOfObject:keyframe];
                break;
            }
        }
        
        Keyframe *fromKeyframe = toIndex > 0 ? self.keyframes[toIndex-1] : nil;
        Keyframe *toKeyframe = self.keyframes[toIndex];
    
        CMTime startTime = fromKeyframe != nil ? fromKeyframe.time : kCMTimeZero;
        CMTime relativeTime = CMTimeSubtract(CMTimeSubtract(info.time, info.timeRange.start), startTime);
        CMTime keyframeDuration = CMTimeSubtract(toKeyframe.time, startTime);
        CGFloat tween = CMTimeGetSeconds(relativeTime)/CMTimeGetSeconds(keyframeDuration);
        tween = MIN(tween, 1.0);
        
        if (toKeyframe.timingFunction) {
            tween = toKeyframe.timingFunction(tween);
        }
        
        KeyframeValueParam *param = [[KeyframeValueParam alloc] init];
        param.fromValue = fromKeyframe.value;
        param.toValue = toKeyframe.value;
        param.tween = tween;
        param.info = info;
        
        if ([toKeyframe.value respondsToSelector:@selector(applyEffectToSourceImage:param:)]) {
            finalImage = [toKeyframe.value applyEffectToSourceImage:sourceImg param:param];
        }
    }
    
    return finalImage;
}

@end


@implementation Keyframe

- (instancetype)init {
    if (self = [super init]) {
        _time = kCMTimeZero;
        
    }
    return self;
}

- (instancetype)initWithTime:(CMTime)time value:(id <KeyframeValue>)value {
    if (self = [super init]) {
        self.time = time;
        self.value = value;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    Keyframe *keyFrame = [[self class] allocWithZone:zone];
    keyFrame.value = [self.value copyWithZone:zone];
    keyFrame.time = self.time;
    keyFrame.timingFunction = self.timingFunction;
    return keyFrame;
}

@end

