//
//  MyFlutterPlatformView.h
//  Runner
//
//  Created by 许大成 on 2023/8/15.
//

#ifndef MyFlutterPlatformView_h
#define MyFlutterPlatformView_h

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface MyFlutterPlatformView : NSObject<FlutterPlatformView>

-(instancetype)initWithWithFrame:(CGRect)frame
                  viewIdentifier:(int64_t)viewId
                       arguments:(id _Nullable)args
                 binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;

@end

NS_ASSUME_NONNULL_END
#endif
