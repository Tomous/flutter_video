//
//  FlutterViewRegistran.h
//  Runner
//
//  Created by 许大成 on 2023/8/17.
//
#ifndef FlutterViewRegistran_h
#define FlutterViewRegistran_h
#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlutterViewRegistran : NSObject
+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry;
@end

NS_ASSUME_NONNULL_END
#endif
