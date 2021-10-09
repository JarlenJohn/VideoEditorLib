//
//  KeyframeVideoConfiguration.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/17/21.
//

#import <Foundation/Foundation.h>
#import "VideoConfiguration.h"
#import "BaseKeyFrameValue.h"

NS_ASSUME_NONNULL_BEGIN

@protocol KeyframeValue;
@class Keyframe;


@interface KeyframeVideoConfiguration : NSObject <VideoConfigurationProtocol>

- (void)insert:(Keyframe *)keyframe;
@end



typedef CGFloat(^TimingFunction)(CGFloat tween);
@interface Keyframe : NSObject <NSCopying>

@property (nonatomic, assign) CMTime time;
@property (nonatomic, strong) BaseKeyFrameValue<KeyframeValue> *value;

@property (nonatomic, copy) TimingFunction timingFunction;

- (instancetype)initWithTime:(CMTime)time value:(id <KeyframeValue>)value;
@end



NS_ASSUME_NONNULL_END
