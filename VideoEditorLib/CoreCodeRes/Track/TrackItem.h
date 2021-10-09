//
//  TrackItem.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/9/21.
// TrackItem 是一个音视频编辑的设置描述对象，类的内部实现了音频数据和视频画面的处理逻辑。

#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import "CompositionProvider.h"
#import "Resource.h"
#import "VideoConfiguration.h"
#import "AudioConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface TrackItem : NSObject <NSCopying, TransitionableVideoProvider, TransitionableAudioProvider>

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) Resource *resource;

//音视频配置
@property (nonatomic, strong) VideoConfiguration *videoConfiguration;
@property (nonatomic, strong) AudioConfiguration *audioConfiguration;

@property (nonatomic, strong) id<VideoTransition> videoTransition;
@property (nonatomic, strong) id<AudioTransition> audioTransition;

- (instancetype)initWithResource:(Resource *)resource;

@end

NS_ASSUME_NONNULL_END
