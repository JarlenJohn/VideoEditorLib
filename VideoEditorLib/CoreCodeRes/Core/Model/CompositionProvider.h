//
//  CompositionProvider.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/8/21.
//

#import <AVFoundation/AVFoundation.h>
#import "VideoTransition.h"
#import "AudioTransition.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CompositionTimeRangeProvider <NSObject>

@property(nonatomic, assign) CMTime startTime;
@property(nonatomic, assign) CMTime duration;

@property(nonatomic, assign) CMTimeRange timeRange;

@end


@protocol VideoCompositionTrackProvider <NSObject>
- (NSInteger)numberOfVideoTracks;
- (AVCompositionTrack *)videoCompositionTrackFor:(AVMutableComposition *)composition atIndex:(NSInteger)index preferredTrackID:(CMPersistentTrackID)trackID;
@end

@protocol AudioCompositionTrackProvider <NSObject>

- (NSInteger)numberOfAudioTracks;
- (AVCompositionTrack *)audioCompositionTrack:(AVMutableComposition *)composition atIndex:(NSInteger)index preferredTrackID:(CMPersistentTrackID)trackID;
@end

@protocol VideoCompositionProvider <NSObject>
/// Apply effect to sourceImage
///
/// - Parameters:
///   - sourceImage: sourceImage is the original image from resource
///   - time: time in timeline
///   - renderSize: the video canvas size
/// - Returns: result image after apply effect
- (CIImage *)applyEffectToSourceImage:(CIImage *)sourceImage atTime:(CMTime)time renderSize:(CGSize)renderSize;
@end

@protocol AudioMixProvider <NSObject>
- (void)configureAudioMixParameters:(AVMutableAudioMixInputParameters *)audioMixParameters;
@end

@protocol VideoProvider <NSObject, CompositionTimeRangeProvider, VideoCompositionTrackProvider, VideoCompositionProvider>
@end

@protocol AudioProvider <NSObject, CompositionTimeRangeProvider, AudioCompositionTrackProvider, AudioMixProvider>
@end


@protocol TransitionableVideoProvider <NSObject, VideoProvider>
@property(nonatomic, strong, readonly) id<VideoTransition> videoTransition;
@end

@protocol TransitionableAudioProvider <NSObject, AudioProvider>
@property(nonatomic, strong, readonly) id<AudioTransition> audioTransition;
@end


NS_ASSUME_NONNULL_END
