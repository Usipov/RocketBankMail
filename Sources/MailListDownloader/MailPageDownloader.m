//
//  MailPageDownloader.m
//  RocketBankMail
//
//  Created by Тимур Юсипов on 02.09.13.
//  Copyright (c) 2013 Usipov Timur. All rights reserved.
//

#import "MailPageDownloader.h"
#import "MailBoxTimestampItem.h"


@interface MailPageDownloader () <NSURLConnectionDelegate> {
    MailListDownloadFinishBlock      _finishBlock;
    MailListDownloadErrorBlock       _errorBlock;
    
    NSMutableData                   *_recievedData;
    NSURLConnection                  *_connection;
}

-(NSURL *)urlForMailBoxItem:(MailBoxItem *)mailbox page:(NSNumber *)page;

@end


@implementation MailPageDownloader

@synthesize mailbox = _mailbox,
            page = _page,
            isBuzy = _isBuzy;

#pragma mark - public methods

-(void)cancelDownload
{
    if (YES == _isBuzy) {
        _isBuzy = NO;
        
        [_connection cancel];
        _connection = nil;
        _recievedData = nil;
        _finishBlock = NULL;
        _errorBlock = NULL;
        
        _mailbox = nil;
        _page = nil;
    }
}

-(void)downloadMailsForMailBoxItem:(MailBoxItem *)mailbox page:(NSNumber *)page finishBlock:(MailListDownloadFinishBlock)finishBlock errorBlock:(MailListDownloadErrorBlock)errorBlock
{
    //start download
    _isBuzy = YES;
    _finishBlock = finishBlock;
    _errorBlock = errorBlock;

    _mailbox = mailbox;
    _page = page;
    
    NSURL *url = [self urlForMailBoxItem: mailbox page: page];
    if (url) {
        NSURLRequest *request = [NSURLRequest requestWithURL: url];
        _connection = [NSURLConnection connectionWithRequest: request delegate: self];

        _isBuzy = YES;
        [_connection start];
    }
}

#pragma mark - private methods

-(NSURL *)urlForMailBoxItem:(MailBoxItem *)mailbox page:(NSNumber *)page
{
    NSURL *url = nil;
    
    if (mailbox.url) {
        NSString *urlSource = [NSString stringWithFormat: @"%@%i", mailbox.url, page.integerValue];
        url = [NSURL URLWithString: urlSource];
    }
    
    return url;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (connection == _connection) {
        _recievedData = [NSMutableData new];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (connection == _connection) {
        [_recievedData appendData: data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _isBuzy = NO;
    
    if (connection == _connection) {
        //parse json data
        if (NSClassFromString(@"NSJSONSerialization")) {
            __autoreleasing NSError *error = nil;
            id object = [NSJSONSerialization JSONObjectWithData: _recievedData options: 0 error: &error];
            if (error) {
                //tell a caller about a mistake
                if (_errorBlock) {
                    _errorBlock(error);
                }
            } else {
                //continue parsing
                if([object isKindOfClass: [NSDictionary class]]) {
                    NSDictionary *mailsData = (NSDictionary *)object;
                    
                    //tell a caller about download complete
                    if (_finishBlock) {
                        _finishBlock(mailsData);
                    }
                }
            }
        }
    } else {
        //parsing for iOS 4 is not implemented within a test task
        if (_errorBlock) {
            NSDictionary *errorInfo = @{
            NSLocalizedDescriptionKey : NSLocalizedString(@"ErorrDescriptionWhileParsing", nil),
            NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"ErrorFailureReasonWhileParsing", nil)
            };
            
            NSError *error = [NSError errorWithDomain: kRocketBankMailErrorDomain code: 0 userInfo: errorInfo];
            
            _errorBlock(error);
        }
    }
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (connection == _connection) {
        #ifdef DEBUG
        NSLog(@"error in %s", __FUNCTION__);
        NSLog(@"%@", error);
        #endif
        
        if (_errorBlock) {
            _errorBlock(error);
        }
    }
}

@end
