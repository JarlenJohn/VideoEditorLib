//
//  AVAudioMixInputParameters+Helper.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/14/21.
//

#import <AVFoundation/AVFoundation.h>
#import "AudioProcessingChain.h"

NS_ASSUME_NONNULL_BEGIN

@class AudioProcessingTapHolder;

@interface AVAudioMixInputParameters (Helper)

@property(nonatomic, strong) AudioProcessingTapHolder *audioProcessingTapHolder;

- (void)appendAudioProcessNode:(id <AudioProcessingNode>)node;

@end

NS_ASSUME_NONNULL_END
