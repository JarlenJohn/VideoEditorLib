//
//  AudioConfiguration.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/9/21.
//

#import <Foundation/Foundation.h>
#import "AudioProcessingChain.h"

NS_ASSUME_NONNULL_BEGIN


@protocol AudioConfigurationProtocol <AudioProcessingNode, NSCopying>

@end


@interface AudioConfiguration : NSObject

@property (nonatomic, assign) CGFloat volume;
@property (nonatomic, strong) NSArray <id<AudioConfigurationProtocol>>*nodes;

+ (instancetype)createDefaultConfiguration;

@end


typedef double(^TimingFunction)(double progress);

@interface VolumeAudioConfiguration : NSObject <AudioConfigurationProtocol>

@property(nonatomic, assign) CMTimeRange timeRange;
@property(nonatomic, assign) CGFloat startVolume;
@property(nonatomic, assign) CGFloat endVolume;
@property(nonatomic, copy) TimingFunction timingFunction;

- (instancetype)initWithTimeRange:(CMTimeRange)timeRange startVolume:(CGFloat)startVolume endVolume:(CGFloat)endVolume;

@end

NS_ASSUME_NONNULL_END
