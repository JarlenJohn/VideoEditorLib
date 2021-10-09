//
//  BaseKeyFrameValue.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/18/21.
//

#import <Foundation/Foundation.h>
#import "VideoConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@class KeyframeValueParam;

@protocol KeyframeValue <NSObject, NSCopying>

- (CIImage *)applyEffectToSourceImage:(CIImage *)sourceImage param:(KeyframeValueParam *)param;
@end


@interface BaseKeyFrameValue : NSObject <KeyframeValue>


@end

@interface TransformKeyframeValue : BaseKeyFrameValue
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) CGFloat rotation;
@property (nonatomic, assign) CGPoint translation;

@end


@interface OpacityKeyframeValue : BaseKeyFrameValue

@property (nonatomic, assign) CGFloat opacity;
@end


#pragma mark - KeyframeValueParam
@interface KeyframeValueParam : NSObject
@property (nonatomic, strong) BaseKeyFrameValue *fromValue;
@property (nonatomic, strong) BaseKeyFrameValue *toValue;
@property (nonatomic, assign) CGFloat tween;
@property (nonatomic, assign) VideoConfigurationEffectInfo info;
@end

NS_ASSUME_NONNULL_END
