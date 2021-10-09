//
//  CompositionGenerator.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/9/21.
//

#import <Foundation/Foundation.h>
#import "Timeline.h"

NS_ASSUME_NONNULL_BEGIN

@interface CompositionGenerator : NSObject

@property (nonatomic, strong) Timeline *timeline;

- (instancetype)initWithTimeline:(Timeline *)timeline;

- (AVPlayerItem *)buildPlayerItem;

@end

@interface TrackInfo<T> : NSObject
@property(nonatomic, strong) AVCompositionTrack *track;
@property(nonatomic, strong) T info;

- (instancetype)initWithTrack:(AVCompositionTrack *)track info:(T)info;

@end

NS_ASSUME_NONNULL_END
