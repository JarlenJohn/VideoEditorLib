//
//  AudioProcessingTapHolder.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/15/21.
//

#import <AVFoundation/AVFoundation.h>
#import "AudioProcessingChain.h"

NS_ASSUME_NONNULL_BEGIN

@interface AudioProcessingTapHolder : NSObject <NSCopying>

@property(nonatomic, assign) MTAudioProcessingTapRef tap;

@property(nonatomic, strong) AudioProcessingChain *audioProcessingChain;



@end

NS_ASSUME_NONNULL_END
