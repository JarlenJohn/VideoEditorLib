//
//  AudioTransition.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/8/21.
//

#import "AudioTransition.h"
#import "AudioConfiguration.h"
#import "TimingFunctionFactory.h"
#import "AVAudioMixInputParameters+Helper.h"

@interface FadeInOutAudioTransition ()

@property(nonatomic, assign) CMTime duration;
@end
@implementation FadeInOutAudioTransition
@synthesize identifier = _identifier;
@synthesize duration = _duration;

- (instancetype)initWithDuration:(CMTime)duration {
    if (self = [super init]) {
        self.duration = duration;
    }
    return self;
}


- (NSString *)identifier {
    return NSStringFromClass([self class]);
}


#pragma mark - AudioTransition
- (void)applyPreviousAudioMixInputParameters:(AVMutableAudioMixInputParameters *)audioMixInputParameters timeRange:(CMTimeRange)timeRange {
    CMTimeRange effectTimeRange = CMTimeRangeFromTimeToTime(CMTimeSubtract(timeRange.start, self.duration), CMTimeRangeGetEnd(timeRange));
    VolumeAudioConfiguration *node = [[VolumeAudioConfiguration alloc] initWithTimeRange:effectTimeRange startVolume:1 endVolume:0];
    node.timingFunction = ^double(double progress) {
        return [TimingFunctionFactory quarticEaseOutWithP:progress];
    };
    [audioMixInputParameters appendAudioProcessNode:node];
}

- (void)applyNextAudioMixInputParameters:(AVMutableAudioMixInputParameters *)audioMixInputParameters timeRange:(CMTimeRange)timeRange {
    CMTimeRange effectTimeRange = CMTimeRangeFromTimeToTime(timeRange.start, CMTimeAdd(timeRange.start, self.duration));
    VolumeAudioConfiguration *node = [[VolumeAudioConfiguration alloc] initWithTimeRange:effectTimeRange startVolume:0 endVolume:1];
    node.timingFunction = ^double(double progress) {
        return [TimingFunctionFactory quarticEaseInWithP:progress];
    };
    [audioMixInputParameters appendAudioProcessNode:node];
}



@end
