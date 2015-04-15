//
//  MSSocketConnection.m
//  NLDSocket
//
//  Created by Simon Heys on 31/03/2015.
//  Copyright (c) 2015 Simon Heys Limited. All rights reserved.
//

#import "MSSocketConnection.h"
#import "DDLog.h"

#ifdef DEBUG
  static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
  static const int ddLogLevel = LOG_LEVEL_ERROR;
#endif

@interface MSSocketConnection () <NSStreamDelegate>
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic) BOOL connected;
@end

@implementation MSSocketConnection

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.shouldReconnectAutomatically = YES;
        self.reconnectTimeInterval = 2;
        self.timeoutTimeInterval = 5;
    }
    return self;
}

- (void)disconnect
{
    if ( nil == self.inputStream && nil == self.outputStream ) {
        return;
    }
    DDLogVerbose(@"disconnect");
    [self.inputStream close];
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream close];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.inputStream = nil;
    self.outputStream = nil;
    self.connected = NO;
}

- (void)connect
{
    [self disconnect];
    DDLogVerbose(@"connect to %@:%@",self.host,@(self.port));
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)(self.host), (UInt32)self.port, &readStream, &writeStream);
    self.inputStream = (__bridge NSInputStream *)readStream;
    self.outputStream = (__bridge NSOutputStream *)writeStream;
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    [self.outputStream open];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
    [self performSelector:@selector(timeout) withObject:nil afterDelay:self.timeoutTimeInterval];
}

- (void)timeout
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
    [self connectFailure];
}

- (void)reconnectAutomatically
{
    DDLogVerbose(@"Will reconnect automatically in %@s",@(self.reconnectTimeInterval));
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connect) object:nil];
    [self performSelector:@selector(connect) withObject:nil afterDelay:self.reconnectTimeInterval];
}

- (void)setShouldReconnectAutomatically:(BOOL)shouldReconnectAutomatically
{
    _shouldReconnectAutomatically = shouldReconnectAutomatically;
    if ( !_shouldReconnectAutomatically ) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connect) object:nil];
    }
}

- (void)sendString:(NSString *)string
{
    DDLogVerbose(@"sendString:%@",string);
	NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding];
	[self.outputStream write:[data bytes] maxLength:[data length]];
    if ( [self.delegate respondsToSelector:@selector(socketConnectionStream:didSendString:)]) {
        [self.delegate socketConnectionStream:self didSendString:string];
    }
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
	DDLogVerbose(@"stream event %@", @(streamEvent));
    switch (streamEvent) {
 
		case NSStreamEventOpenCompleted:
			[self connectSuccess:theStream];
			break;
            
        case NSStreamEventHasSpaceAvailable:
            DDLogVerbose(@"Stream has space available");
            break;
 
		case NSStreamEventHasBytesAvailable:
            if (theStream == self.inputStream) {
     
                uint8_t buffer[1024];
                NSInteger len;
         
                while ([self.inputStream hasBytesAvailable]) {
                    len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
         
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
         
                        if (nil != output) {
                            NSLog(@"server said: %@", output);
                            if ( [self.delegate respondsToSelector:@selector(socketConnectionStream:didReceiveString:)]) {
                                [self.delegate socketConnectionStream:self didReceiveString:output];
                            }
                        }
                    }
                }
            }
			break;
 
		case NSStreamEventErrorOccurred:
			[self connectFailure];
			break;
 
		case NSStreamEventEndEncountered:
            [self disconnect];
            if ( [self.delegate respondsToSelector:@selector(socketConnectionStreamDidDisconnect:willReconnectAutomatically:)]) {
                [self.delegate socketConnectionStreamDidDisconnect:self willReconnectAutomatically:self.shouldReconnectAutomatically];
            }
            if ( self.shouldReconnectAutomatically ) {
                [self reconnectAutomatically];
            }
			break;
 
		default:
			DDLogVerbose(@"Unknown event");
	}
}

- (void)connectSuccess:(NSStream *)theStream
{
    DDLogVerbose(@"Stream opened");
    if ( theStream == self.outputStream ) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
        self.connected = YES;
        if ( [self.delegate respondsToSelector:@selector(socketConnectionStreamDidConnect:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate socketConnectionStreamDidConnect:self];
            });
        }
    }
}

- (void)connectFailure
{
    [self disconnect];
    DDLogError(@"Can not connect to the host!");
    if ( [self.delegate respondsToSelector:@selector(socketConnectionStreamDidFailToConnect:willReconnectAutomatically:)]) {
        [self.delegate socketConnectionStreamDidFailToConnect:self willReconnectAutomatically:self.shouldReconnectAutomatically];
    }
    if ( self.shouldReconnectAutomatically ) {
        [self reconnectAutomatically];
    }
}

@end
