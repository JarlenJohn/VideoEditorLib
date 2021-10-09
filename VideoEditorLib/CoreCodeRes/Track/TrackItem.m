//
//  TrackItem.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/9/21.
//

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import "TrackItem.h"
#import "AVCompositionTrack+Helper.h"
#import "TimeRangeHelper.h"
#import "AVAudioMixInputParameters+Helper.h"
#import "AudioProcessingTapHolder.h"

@interface TrackItem () {
    CMTime _duration;
    CMTimeRange _timeRange;
}
@end

@implementation TrackItem

@dynamic duration;
@synthesize startTime;
@synthesize timeRange = _timeRange;
@synthesize audioTransition;
@synthesize videoTransition;

- (instancetype)initWithResource:(Resource *)resource {
    if (self = [super init]) {
        self.identifier = [[NSProcessInfo processInfo] globallyUniqueString];
        self.resource = resource;
        _videoConfiguration = [VideoConfiguration createDefaultConfiguration];
        _audioConfiguration = [AudioConfiguration createDefaultConfiguration];
        
        self.startTime = kCMTimeZero;
    }
    return self;
}


#pragma mark - NSCopying
- (id)copyWithZone:(nullable NSZone *)zone {
    TrackItem *item = [[[self class] alloc] initWithResource:self.resource.copy];
    item.identifier = self.identifier;
    item.videoTransition = self.videoTransition;
    item.audioTransition = self.audioTransition;
    item.startTime = self.startTime;
    item.duration = self.duration;
    item.videoConfiguration = self.videoConfiguration.copy;
    item.audioConfiguration = self.audioConfiguration.copy;
    return item;
}

#pragma mark - CompositionTimeRangeProvider
- (void)setDuration:(CMTime)duration {
    _duration = duration;
    self.resource.scaledDuration = duration;
}

- (CMTime)duration {
    return self.resource.scaledDuration;
}

- (CMTimeRange)timeRange {
    return CMTimeRangeMake(self.startTime, self.duration);
}

#pragma mark - TransitionableVideoProvider
- (NSInteger)numberOfVideoTracks {
    return [self.resource tracksForType:AVMediaTypeVideo].count;
}

- (AVCompositionTrack *)videoCompositionTrackFor:(AVMutableComposition *)composition
                                         atIndex:(NSInteger)index
                                preferredTrackID:(CMPersistentTrackID)preferredTrackID {
    ResourceTrackInfo *trackInfo = [self.resource trackInfoForType:AVMediaTypeVideo atIndex:index];
    AVAssetTrack *track = (*trackInfo).track;
    
    AVMutableCompositionTrack *compositionTrack = nil;
    AVMutableCompositionTrack *preferredTrack = [composition trackWithTrackID:preferredTrackID];
    if (preferredTrack) {
        compositionTrack = preferredTrack;
    }else {
        compositionTrack = [composition addMutableTrackWithMediaType:track.mediaType preferredTrackID:preferredTrackID];
    }
    
    if (compositionTrack) {
        NSString *timerangeKey = [TimeRangeHelper vf_identifierFromTimeRange:self.timeRange];
        [compositionTrack.preferredTransforms setObject:[NSValue valueWithCGAffineTransform:track.preferredTransform] forKey:timerangeKey];
        [compositionTrack removeTimeRange:(CMTimeRangeMake(self.timeRange.start, trackInfo->scaleToDuration))];
        [compositionTrack insertTimeRange:trackInfo->selectedTimeRange ofTrack:trackInfo->track atTime:self.timeRange.start error:nil];
        [compositionTrack scaleTimeRange:CMTimeRangeMake(self.timeRange.start, trackInfo->selectedTimeRange.duration) toDuration:trackInfo->scaleToDuration];
    }
    
    free(trackInfo);
    return compositionTrack;
}

- (CIImage *)applyEffectToSourceImage:(CIImage *)sourceImage atTime:(CMTime)time renderSize:(CGSize)renderSize {
    CIImage *finalImage = nil;
    CMTime relativeTime = CMTimeSubtract(time, self.startTime);
    finalImage = [self.resource imageAtTime:relativeTime renderSize:renderSize];
    if (!finalImage) {
        finalImage = sourceImage;
    }
    
    VideoConfigurationEffectInfo info = {time, renderSize, self.timeRange};
    
    finalImage = [self.videoConfiguration applyEffectToSourceImage:finalImage info:info];
    
    return finalImage;
}


#pragma mark - TransitionableAudioProvider
- (NSInteger)numberOfAudioTracks {
    return [[self.resource tracksForType:AVMediaTypeAudio] count];
}

- (AVCompositionTrack *)audioCompositionTrack:(AVMutableComposition *)composition atIndex:(NSInteger)index preferredTrackID:(CMPersistentTrackID)preferredTrackID {
    ResourceTrackInfo *trackInfo = [self.resource trackInfoForType:AVMediaTypeAudio atIndex:index];
    AVMutableCompositionTrack *compositionTrack = nil;
    AVMutableCompositionTrack *preferredTrack = [composition trackWithTrackID:preferredTrackID];
    if (preferredTrack) {
        compositionTrack = preferredTrack;
    }else {
        compositionTrack = [composition addMutableTrackWithMediaType:trackInfo->track.mediaType preferredTrackID:preferredTrackID];
    }
    if (compositionTrack) {
        [compositionTrack insertTimeRange:trackInfo->selectedTimeRange ofTrack:trackInfo->track atTime:self.timeRange.start error:nil];
        [compositionTrack scaleTimeRange:CMTimeRangeMake(self.timeRange.start, trackInfo->selectedTimeRange.duration) toDuration:trackInfo->scaleToDuration];
    }
    
    free(trackInfo);
    return compositionTrack;
}

- (void)configureAudioMixParameters:(AVMutableAudioMixInputParameters *)audioMixParameters {
    CGFloat volume = self.audioConfiguration.volume;
    [audioMixParameters setVolumeRampFromStartVolume:volume toEndVolume:volume timeRange:self.timeRange];
    if (self.audioConfiguration.nodes.count > 0) {
        NSAssert(NO, @"自定义音视频处理，可能会存在bug及内存泄漏，注意测试！！！");
        if (audioMixParameters.audioProcessingTapHolder == nil) {
            audioMixParameters.audioProcessingTapHolder = [[AudioProcessingTapHolder alloc] init];
        }
        [audioMixParameters.audioProcessingTapHolder.audioProcessingChain.nodes addObjectsFromArray:self.audioConfiguration.nodes];
    }
}

@end

