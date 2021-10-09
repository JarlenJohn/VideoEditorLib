//
//  AudioProcessingChain.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/9/21.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AudioProcessingNode <NSObject>

- (void)processTimeRange:(CMTimeRange)timerange bufferListInOut:(AudioBufferList *)audioBufferList;
@end

@interface AudioProcessingChain : NSObject<NSCopying>

@property (nonatomic, strong) NSMutableArray <id<AudioProcessingNode>>*nodes;

- (void)processTimeRange:(CMTimeRange)timerange bufferListInOut:(AudioBufferList *)bufferListInOut;

@end

NS_ASSUME_NONNULL_END
