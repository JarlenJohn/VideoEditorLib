//
//  TrackConfiguration.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/9/21.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct VideoConfigurationEffectInfo {
    CMTime time;
    CGSize renderSize;
    CMTimeRange timeRange;
}VideoConfigurationEffectInfo;


typedef NS_ENUM(NSUInteger, BaseContentMode) {
    BaseContentModeAspectFit,
    BaseContentModeAspectFill,
    BaseContentModeAspectCustom,
};

@protocol VideoConfigurationProtocol <NSObject, NSCopying>

- (CIImage *)applyEffectToSourceImage:(CIImage *)sourceImg info:(VideoConfigurationEffectInfo)info;
@end

@interface VideoConfiguration : NSObject<VideoConfigurationProtocol>

@property (nonatomic, assign) BaseContentMode contentMode;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGAffineTransform transform;
@property (nonatomic, assign) CGFloat opacity;
@property (nonatomic, strong) NSMutableArray <id<VideoConfigurationProtocol>>*configurations;

+ (instancetype)createDefaultConfiguration;

@end


NS_ASSUME_NONNULL_END
