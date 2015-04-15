//
//  MSViewController.m
//  MSSocketConnection
//
//  Created by Simon Heys on 04/15/2015.
//  Copyright (c) 2014 Simon Heys. All rights reserved.
//

#import "MSViewController.h"
#import "MSSocketConnection.h"

@interface MSViewController () <MSSocketConnectionDelegate>
@property (nonatomic, strong) MSSocketConnection *socketConnection;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITextField *hostTextField;
@property (weak, nonatomic) IBOutlet UITextField *portTextField;
@property (weak, nonatomic) IBOutlet UITextView *debugTextView;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@end

@implementation MSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.socketConnection = [MSSocketConnection new];
    self.socketConnection.delegate = self;
}

- (void)socketConnectionStreamDidConnect:(MSSocketConnection *)connection
{
    [self debugString:@"Connected"];
    [self updateConnectButton];
//    [self.socketConnection sendString:@"Hello!"];
}

- (void)socketConnectionStreamDidDisconnect:(MSSocketConnection *)connection willReconnectAutomatically:(BOOL)willReconnectAutomatically
{
    [self debugString:@"Disconnected"];
    [self updateConnectButton];
}

- (void)updateConnectButton
{
    [self.connectButton setTitle:self.socketConnection.connected ? @"Disconnect" : @"Connect" forState:UIControlStateNormal];
}

- (IBAction)connect:(id)sender
{
    if ( !self.socketConnection.connected ) {
        NSUInteger port = [self.portTextField.text integerValue];
        [self debugString:[NSString stringWithFormat:@"Connecting to host %@:%@",self.hostTextField.text,@(port)]];
        self.socketConnection.host = self.hostTextField.text;
        self.socketConnection.port = port;
        self.socketConnection.shouldReconnectAutomatically = YES;
        self.socketConnection.reconnectTimeInterval = 2;
        self.socketConnection.timeoutTimeInterval = 1;
        [self.socketConnection connect];
    }
    else {
        [self.socketConnection disconnect];
        [self updateConnectButton];
        [self debugString:@"Disconnected"];
    }
}

- (void)socketConnectionStreamDidFailToConnect:(MSSocketConnection *)connection
{
    [self debugString:@"Could not connect to host"];
}

- (void)socketConnectionStream:(MSSocketConnection *)connection didReceiveString:(NSString *)string
{
    [self debugString:[NSString stringWithFormat:@"Received: %@",string]];
}

- (void)socketConnectionStream:(MSSocketConnection *)connection didSendString:(NSString *)string
{
    [self debugString:[NSString stringWithFormat:@"Sent: %@",string]];
}

- (IBAction)sendWithNewLine:(id)sender
{
    [self.socketConnection sendString:[NSString stringWithFormat:@"%@\n",self.textField.text]];
}

- (IBAction)send:(id)sender
{
    [self.socketConnection sendString:self.textField.text];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)debugString:(NSString *)string
{
    self.debugTextView.text = [self.debugTextView.text stringByAppendingString:[NSString stringWithFormat:@"%@\n",string]];
}

@end
