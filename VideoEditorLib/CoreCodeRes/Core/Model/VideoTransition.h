//
//  VideoTransition.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/8/21.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreImage/CoreImage.h>


NS_ASSUME_NONNULL_BEGIN

@protocol VideoTransition <NSObject>

@property(nonatomic, copy, readonly) NSString *identifier;
@property(nonatomic, assign, readonly) CMTime duration;

- (CIImage *)renderImageWithForegroundImage:(CIImage *)foregroundImage
                            backgroundImage:(CIImage *)backgroundImage
                             forTweenFactor:(CGFloat)tween
                                 renderSize:(CGSize)renderSize;

@end

@interface NoneTransition : NSObject<VideoTransition>

- (instancetype)initWithDuration:(CMTime)duration;

@end

@interface CrossDissolveTransition : NoneTransition

@end

@interface SwipeTransition : NoneTransition

@end


@interface PushTransition : NoneTransition 

@end


@interface BoundingUpTransition : NoneTransition

@end


@interface FadeTransition : NoneTransition

@end

NS_ASSUME_NONNULL_END
