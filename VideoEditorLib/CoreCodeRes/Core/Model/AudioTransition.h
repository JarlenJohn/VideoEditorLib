//
//  AudioTransition.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/8/21.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AudioTransition <NSObject>

@property(nonatomic, copy, readonly) NSString *identifier;
@property(nonatomic, assign, readonly) CMTime duration;

/// Configure AVMutableAudioMixInputParameters for audio that is about to disappear
///
/// - Parameters:
///   - audioMixInputParameters: The parameters for inputs to the mix
///   - timeRange: The source track's time range
- (void)applyPreviousAudioMixInputParameters:(AVMutableAudioMixInputParameters *) audioMixInputParameters timeRange:(CMTimeRange)timeRange;

/// Configure AVMutableAudioMixInputParameters for upcoming audio
///
/// - Parameters:
///   - audioMixInputParameters: The parameters for inputs to the mix
///   - timeRange: The source track's time range
- (void)applyNextAudioMixInputParameters:(AVMutableAudioMixInputParameters *)audioMixInputParameters timeRange:(CMTimeRange)timeRange;

@end


@interface FadeInOutAudioTransition : NSObject <AudioTransition>

- (instancetype)initWithDuration:(CMTime)duration;

@end

NS_ASSUME_NONNULL_END
