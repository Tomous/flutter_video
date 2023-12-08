//
//  PlayerLayerView.m
//  Runner
//
//  Created by 许大成 on 2023/8/17.
//

#import "PlayerLayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation PlayerLayerView

+ (Class)layerClass {
    
    return [AVPlayerLayer class];
}

@end
