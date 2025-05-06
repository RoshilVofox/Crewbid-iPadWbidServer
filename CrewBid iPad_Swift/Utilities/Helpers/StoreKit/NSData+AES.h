//
//  NSData+AES.h
//  CrewBid
//
//  Created by RJ on 12/26/13.
//  Copyright (c) 2013 Brainbag Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (AES256)

- (NSData *)AES256EncryptWithKey:(NSString *)key;
- (NSData *)AES256DecryptWithKey:(NSString *)key;

@end
