//
//  MSSocketConnection.h
//  NLDSocket
//
//  Created by Simon Heys on 31/03/2015.
//  Copyright (c) 2015 Simon Heys Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MSSocketConnectionDelegate;

@interface MSSocketConnection : NSObject
@property (nonatomic, assign) id<MSSocketConnectionDelegate>delegate;
@property (nonatomic, readonly) BOOL connected;
@property (nonatomic) BOOL shouldReconnectAutomatically;
@property (nonatomic) NSTimeInterval reconnectTimeInterval;
@property (nonatomic) NSTimeInterval timeoutTimeInterval;
@property (nonatomic, strong) NSString *host;
@property (nonatomic) NSUInteger port;
- (void)sendString:(NSString *)string;
- (void)connect;
- (void)disconnect;
@end

@protocol MSSocketConnectionDelegate <NSObject>
@optional
- (void)socketConnectionStreamDidConnect:(MSSocketConnection *)connection;
- (void)socketConnectionStreamDidDisconnect:(MSSocketConnection *)connection willReconnectAutomatically:(BOOL)willReconnectAutomatically;
- (void)socketConnectionStream:(MSSocketConnection *)connection didReceiveString:(NSString *)string;
- (void)socketConnectionStream:(MSSocketConnection *)connection didSendString:(NSString *)string;
- (void)socketConnectionStreamDidFailToConnect:(MSSocketConnection *)connection willReconnectAutomatically:(BOOL)willReconnectAutomatically;
@end
