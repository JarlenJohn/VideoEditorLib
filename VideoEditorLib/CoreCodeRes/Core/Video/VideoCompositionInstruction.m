//
//  VideoCompositionInstruction.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/10/21.
//

#import "VideoCompositionInstruction.h"
#import "VideoCompositionLayerInstruction.h"

@interface VideoCompositionInstruction()

@end


@implementation VideoCompositionInstruction

@synthesize timeRange = _timeRange;
@synthesize enablePostProcessing = _enablePostProcessing;
@synthesize containsTweening = _containsTweening;
@synthesize requiredSourceTrackIDs = _requiredSourceTrackIDs;
@synthesize passthroughTrackID = _passthroughTrackID;

- (instancetype)initWithPassthroughTrackID:(CMPersistentTrackID)thePassthroughTrackID forTimeRange:(CMTimeRange)theTimeRange {
    if (self = [super init]) {
        _passthroughTrackID = thePassthroughTrackID;
        _timeRange = theTimeRange;
        
        _requiredSourceTrackIDs = [[NSMutableArray alloc] init];
        _containsTweening = NO;
        _enablePostProcessing = NO;
    }
    return self;
}

- (instancetype)initWithSourceTrackIDs:(NSArray <NSValue *>*)theSourceTrackIDs forTimeRange:(CMTimeRange)theTimeRange {
    if (self = [super init]) {
        _requiredSourceTrackIDs = theSourceTrackIDs;
        _timeRange = theTimeRange;
        
        _passthroughTrackID = kCMPersistentTrackID_Invalid;
        _containsTweening = YES;
        _enablePostProcessing = NO;
    }
    
    return self;
}

- (CIImage *)applyRequest:(AVAsynchronousVideoCompositionRequest *)request {
    CMTime time = request.compositionTime;
    CGSize renderSize = request. renderContext.size;
    
    NSMutableArray <VideoCompositionLayerInstruction *>*otherLayerInstructions = [[NSMutableArray alloc] init];
    NSMutableArray <VideoCompositionLayerInstruction *>*mainLayerInstructions = [[NSMutableArray alloc] init];
    
    for (VideoCompositionLayerInstruction *layerInstruction in self.layerInstructions) {
        BOOL trackIdInMain = NO;
        for (NSNumber *trackID in self.mainTrackIDs) {
            if ([trackID intValue] == layerInstruction.trackID) {
                trackIdInMain = YES;
                break;
            }
        }
        if (trackIdInMain) {
            [mainLayerInstructions addObject:layerInstruction];
        }else {
            [otherLayerInstructions addObject:layerInstruction];
        }
    }
    
    CIImage *image = nil;
    
    if (mainLayerInstructions.count == 2) {
        VideoCompositionLayerInstruction *layerInstruction1 = nil;
        VideoCompositionLayerInstruction *layerInstruction2 = nil;
        if (CMTIME_COMPARE_INLINE(CMTimeRangeGetEnd(mainLayerInstructions[0].timeRange), <, CMTimeRangeGetEnd(mainLayerInstructions[1].timeRange))) {
            layerInstruction1 = mainLayerInstructions[0];
            layerInstruction2 = mainLayerInstructions[1];
        }else {
            layerInstruction1 = mainLayerInstructions[1];
            layerInstruction2 = mainLayerInstructions[0];
        }
        
        CVPixelBufferRef sourcePixel1 = [request sourceFrameByTrackID:layerInstruction1.trackID];
        CVPixelBufferRef sourcePixel2 = [request sourceFrameByTrackID:layerInstruction2.trackID];
        if (sourcePixel1 && sourcePixel2) {
            CIImage *image1 = [self generateImageFromPixelBuffer:sourcePixel1];
            CIImage *sourceImage1 = [layerInstruction1 applySourceImage:image1 atTime:time renderSize:renderSize];
            id<VideoTransition> transition = layerInstruction1.transition;
            if (transition) {
                CIImage *image2 = [self generateImageFromPixelBuffer:sourcePixel2];
                CIImage *sourceImage2 = [layerInstruction2 applySourceImage:image2 atTime:time renderSize:renderSize];
                
                CMTimeRange transitionTimeRange = CMTimeRangeGetIntersection(layerInstruction1.timeRange, layerInstruction2.timeRange);
                CGFloat tweenFactor = [self factorForTimeInRangeAtTime:time range:transitionTimeRange];
                CIImage *transitionImage = [transition renderImageWithForegroundImage:sourceImage2 backgroundImage:sourceImage1 forTweenFactor:tweenFactor renderSize:renderSize];
                image = transitionImage;
            }else {
                image = sourceImage1;
            }
        }
    }else {
        for (VideoCompositionLayerInstruction *layerInstruction in mainLayerInstructions) {
            CVPixelBufferRef sourcePixel = [request sourceFrameByTrackID:layerInstruction.trackID];
            if (sourcePixel) {
                CIImage *sourceImage = [layerInstruction applySourceImage:[[CIImage alloc] initWithCVPixelBuffer:sourcePixel] atTime:time renderSize:renderSize];
                if (image) {
                    image = [sourceImage imageByCompositingOverImage:image];
                }else {
                    image = sourceImage;
                }
            }
        }
    }
    
    for (VideoCompositionLayerInstruction *layerInstruction in otherLayerInstructions) {
        CVPixelBufferRef sourcePixel = [request sourceFrameByTrackID:layerInstruction.trackID];
        if (sourcePixel) {
            CIImage *sourceImage = [layerInstruction applySourceImage:[[CIImage alloc] initWithCVPixelBuffer:sourcePixel] atTime:time renderSize:renderSize];
            if (image) {
                image = [sourceImage imageByCompositingOverImage:image];
            }else {
                image = sourceImage;
            }
        }
    }
    
    if (self.passingThroughVideoCompositionProvider && image != nil) {
        image = [self.passingThroughVideoCompositionProvider applyEffectToSourceImage:image atTime:time renderSize:renderSize];
    }
    return image;
}

- (CGFloat)factorForTimeInRangeAtTime:(CMTime)time range:(CMTimeRange)range {
    CMTime elapsed = CMTimeSubtract(time, range.start);
    return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration);
}

- (CIImage *)generateImageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CIImage *image = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer];
    CFDictionaryRef attr = CVBufferGetAttachments(pixelBuffer, kCVAttachmentMode_ShouldPropagate);
    if (attr && CFDictionaryGetCount(attr) > 0) {
        CFDictionaryRef aspectRatioDict = CFDictionaryGetValue(attr, kCVImageBufferPixelAspectRatioKey);
        if (aspectRatioDict && CFDictionaryGetCount(aspectRatioDict) > 0) {
            CFNumberRef widthNum = (CFNumberRef)CFDictionaryGetValue(aspectRatioDict, kCVImageBufferPixelAspectRatioHorizontalSpacingKey);
            CFNumberRef heightNum = (CFNumberRef)CFDictionaryGetValue(aspectRatioDict, kCVImageBufferPixelAspectRatioVerticalSpacingKey);
            CGFloat width = 0;
            CGFloat height = 0;
            CFNumberGetValue(widthNum, kCFNumberFloatType, &width);
            CFNumberGetValue(heightNum, kCFNumberFloatType, &height);
            
            if (width != 0 && height != 0) {
                image = [image imageByApplyingTransform:CGAffineTransformMakeScale(width/height, 1)];
            }
        }
    }
    return image;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<VideoCompositionInstruction, timeRange: {start: %f, duration: %f, requiredSourceTrackIDs:%@",
            CMTimeGetSeconds(self.timeRange.start), CMTimeGetSeconds(self.timeRange.duration), self.requiredSourceTrackIDs];
}

@end
