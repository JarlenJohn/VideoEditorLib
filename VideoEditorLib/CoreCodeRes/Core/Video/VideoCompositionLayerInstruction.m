//
//  VideoCompositionLayerInstruction.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/13/21.
//

#import "VideoCompositionLayerInstruction.h"
#import "CIImage+Helper.h"

@implementation VideoCompositionLayerInstruction

- (instancetype)initWithTrackID:(CMPersistentTrackID)trackID videoCompositionProvider:(id)videoCompositionProvider {
    if (self = [super init]) {
        _trackID = trackID;
        _videoCompositionProvider = videoCompositionProvider;
        
        _timeRange = kCMTimeRangeZero;
        _prefferdTransform = CGAffineTransformIdentity;
    }
    return self;
}

- (CIImage *)applySourceImage:(CIImage *)sourceImage atTime:(CMTime)time renderSize:(CGSize)renderSize {
    CIImage *tmpImage = sourceImage;
    
    if (!CGAffineTransformEqualToTransform(self.prefferdTransform, CGAffineTransformIdentity)) {
        tmpImage = [[[tmpImage flipYCoordinate] imageByApplyingTransform:self.prefferdTransform] flipYCoordinate];
    }
    tmpImage = [self.videoCompositionProvider applyEffectToSourceImage:tmpImage atTime:time renderSize:renderSize];
    return tmpImage;
}
 

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<VideoCompositionLayerInstruction, trackID:%d, timeRange:{start:%lf, duration:%lf}",
            self.trackID, CMTimeGetSeconds(self.timeRange.start), CMTimeGetSeconds(self.timeRange.duration)];
}
    
@end
