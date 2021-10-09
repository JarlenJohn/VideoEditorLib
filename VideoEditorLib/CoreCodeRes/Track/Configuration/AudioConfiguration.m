//
//  AudioConfiguration.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/9/21.
//

#import "AudioConfiguration.h"
#import "AudioMixer.h"

@implementation AudioConfiguration

+ (instancetype)createDefaultConfiguration {
    return [[self alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
        _volume = 1.0;
        _nodes = @[];
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    AudioConfiguration *audioConfig = [[[self class] allocWithZone:zone] init];
    audioConfig.volume = self.volume;
    
    NSMutableArray *nodeArrs = [[NSMutableArray alloc] init];
    for (id <AudioConfigurationProtocol>node in self.nodes) {
        [nodeArrs addObject:[node copyWithZone:NULL]];
    }
    audioConfig.nodes = nodeArrs;
    return audioConfig;
}

@end



@implementation VolumeAudioConfiguration

- (instancetype)initWithTimeRange:(CMTimeRange)timeRange startVolume:(CGFloat)startVolume endVolume:(CGFloat)endVolume {
    if (self = [super init]) {
        self.timeRange = timeRange;
        self.startVolume = startVolume;
        self.endVolume = endVolume;
    }
    return self;
}

- (void)processTimeRange:(CMTimeRange)timerange bufferListInOut:(AudioBufferList *)audioBufferList {
    if (CMTIMERANGE_IS_VALID(timerange)) {
        CMTimeRange interectTimeRange = CMTimeRangeGetIntersection(self.timeRange, timerange);
        if (CMTimeGetSeconds(interectTimeRange.duration) > 0) {
            CGFloat percent = (CMTimeGetSeconds(CMTimeRangeGetEnd(timerange)) - CMTimeGetSeconds(self.timeRange.start)) / CMTimeGetSeconds(self.timeRange.duration);
            if (self.timingFunction) {
                percent = _timingFunction(percent);
            }
            
            CGFloat volume = self.startVolume + (self.endVolume - self.startVolume)*(CGFloat)percent;
            [AudioMixer changeVolumeForBufferList:audioBufferList volume:volume];
        }
    }
}

- (id)copyWithZone:(NSZone *)zone {
    VolumeAudioConfiguration *configuration = [[[self class] alloc] initWithTimeRange:self.timeRange startVolume:self.startVolume endVolume:self.endVolume];
    configuration.timingFunction = self.timingFunction;
    return configuration;
}

@end
