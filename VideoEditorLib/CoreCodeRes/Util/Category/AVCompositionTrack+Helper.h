//
//  AVCompositionTrack+Helper.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/10/21.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVCompositionTrack (Helper)

//NSValue存放的是CGAffineTransform
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSValue *> *preferredTransforms;


@end

NS_ASSUME_NONNULL_END
