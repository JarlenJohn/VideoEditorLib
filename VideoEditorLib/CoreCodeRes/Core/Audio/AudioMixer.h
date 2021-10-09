//
//  AudioMixer.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/15/21.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioMixer : NSObject

+(void)changeVolumeForBufferList:(AudioBufferList *)bufferList volume:(CGFloat)volume;

@end

NS_ASSUME_NONNULL_END
