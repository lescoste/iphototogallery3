//
// Copyright (c) Zach Wily
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
// 
// - Redistributions of source code must retain the above copyright notice, this 
//     list of conditions and the following disclaimer.
// 
// - Redistributions in binary form must reproduce the above copyright notice, this
//     list of conditions and the following disclaimer in the documentation and/or 
//     other materials provided with the distribution.
// 
// - Neither the name of Zach Wily nor the names of its contributors may be used to 
//     endorse or promote products derived from this software without specific prior 
//     written permission.
// 
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR 
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
//   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON 
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "json/JSON.h"
#import "SCZWGalleryAlbum.h"
#import "SCZWGalleryItem.h"
#import "SCZWMutableURLRequest.h"

#import <SystemConfiguration/SystemConfiguration.h>

#define BUFSIZE 1024

@implementation SCZWGalleryAlbum

#pragma mark -

- (id)initWithTitle:(NSString*)newTitle name:(NSString*)newName gallery:(SCZWGallery*)newGallery {
    return [self initWithTitle:newTitle name:newName summary:nil nestedIn:nil gallery:newGallery];
}

+ (SCZWGalleryAlbum*)albumWithTitle:(NSString*)newTitle name:(NSString*)newName gallery:(SCZWGallery*)newGallery {
    return [[[SCZWGalleryAlbum alloc] initWithTitle:newTitle name:newName gallery:newGallery] autorelease];
}

- (id)initWithTitle:(NSString*)newTitle name:(NSString*)newName summary:(NSString*)newSummary nestedIn:(SCZWGalleryAlbum*)newParent gallery:(SCZWGallery*)newGallery
{
    title = [newTitle retain];
    name = [newName retain];
    gallery = [newGallery retain];
    summary = [newSummary retain];
    parent = [newParent retain];
    items = [[NSMutableArray array] retain];
    
    return self;
}

- (SCZWGalleryAlbum*)albumWithTitle:(NSString*)newTitle name:(NSString*)newName summary:(NSString*)newSummary nestedIn:(SCZWGalleryAlbum*)newParent gallery:(SCZWGallery*)newGallery
{
    return [[[SCZWGalleryAlbum alloc] initWithTitle:newTitle name:newName summary:newSummary nestedIn:parent gallery:newGallery] autorelease];
}

- (void)dealloc
{
    [title release];
    [name release];
    [summary release];
    [gallery release];
    [parent release];
    [children release];
    [items release];
    
    [super dealloc];
}

#pragma mark NSComparison

- (BOOL)isEqual:(id)otherAlbum 
{
    return ([gallery isEqual:[otherAlbum gallery]] && [name isEqual:[otherAlbum name]]);
}

#pragma mark Accessors

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id)newDelegate {
    delegate = newDelegate;
}

- (NSString*)title {
    return title;
}

- (void)setTitle:(NSString*)newTitle
{
    [newTitle retain];
    [title release];
    title = newTitle;
}

- (NSString*)url {
    return url;
}

- (void)setUrl:(NSString*)newUrl
{
    [newUrl retain];
    [url release];
    url = newUrl;
}

- (NSString*)parenturl {
    return parenturl;
}

- (void)setParenturl:(NSString*)newParenturl
{
    [newParenturl retain];
    [parenturl release];
    parenturl = newParenturl;
}

- (NSString*)name 
{
    return name;
}

- (void)setName:(NSString*)newName
{
    [newName retain];
    [name release];
    name = newName;
}

- (NSString*)summary
{
    return summary;
}

- (void)setSummary:(NSString*)newSummary
{
    [newSummary retain];
    [summary release];
    summary = newSummary;
}

- (SCZWGallery*)gallery
{
    return gallery;
}

- (void)setGallery:(SCZWGallery*)newGallery
{
    [newGallery retain];
    [gallery release];
    gallery = newGallery;
}

- (void)setParent:(SCZWGalleryAlbum*)newParent {
    [newParent retain];
    [parent release];
    parent = newParent;
}

- (SCZWGalleryAlbum*)parent {
    return parent;
}

- (void)addChild:(SCZWGalleryAlbum*)child {
    if (children == nil) {
        children = [[NSMutableArray array] retain];
    }
    [children addObject:child];
}

- (NSArray*)children {
    return children;
}

- (void)setCanAddItem:(BOOL)newCanAddItem {
    canAddItem = newCanAddItem;
}

- (BOOL)canAddItem {
    return canAddItem;
}

- (void)setCanAddTags:(BOOL)newCanAddTags {
    canAddTags = newCanAddTags;
}
- (BOOL)canAddTags {
    return canAddTags;
}

#pragma mark -

- (BOOL)canAddItemToAlbumOrSub {
    if (canAddItem)
        return TRUE;
    if (children == nil) 
        return FALSE;
    
    NSEnumerator *enumerator = [children objectEnumerator];
    id album;
    while (album = [enumerator nextObject]) {
        if ([album canAddItemToAlbumOrSub]) 
            return TRUE;
    }
    return FALSE;
}

- (void)setCanAddSubAlbum:(BOOL)newCanAddSubAlbum {
    canAddSubAlbum = newCanAddSubAlbum;
}

- (BOOL)canAddSubAlbum {
    return canAddSubAlbum;
}

- (BOOL)canAddSubToAlbumOrSub
{
    if (canAddSubAlbum)
        return TRUE;
    if (children == nil)
        return FALSE;
    NSEnumerator *enumerator = [children objectEnumerator];
    id album;
    while (album = [enumerator nextObject]) {
        if ([album canAddSubToAlbumOrSub]) 
            return TRUE;
    }
    return FALSE;
}

- (int)depth {
    int d = 0;
    SCZWGalleryAlbum* cur_parent = parent;
    while (cur_parent) {
        cur_parent = [cur_parent parent];
        d++;
    }
    return d;
}

- (void)cancelOperation
{
    cancelled = YES;
}


/*
 Uploading a new file
 
 To upload a new file, use a POST request to the parent album URL, providing the actual file (and filename), along with the new entity's details as a MIME multipart body.
 Request
 Parameters:
 entity: a JSON-encoded object containing the fields of the new entity (name, description, etc. - *not tags*)
 file: the picture data and filename
 
 POST /gallery3/index.php/rest/item/1 HTTP/1.1
 X-Gallery-Request-Method: post
 X-Gallery-Request-Key: ...
 Content-Length: 142114
 Content-Type: multipart/form-data; boundary=roPK9J3DoG4SCZWP6etiDuJ97h-zeNAph
 
 
 --roPK9J3DoG4SCZWP6etiDuJ97h-zeNAph
 Content-Disposition: form-data; name="entity"
 Content-Type: text/plain; charset=UTF-8
 Content-Transfer-Encoding: 8bit
 
 {"name":"Voeux2010.jpg","type":"photo"}
 
 --roPK9J3DoG4SCZWP6etiDuJ97h-zeNAph
 Content-Disposition: form-data; name="file"; filename="Voeux2010.jpg"
 Content-Type: application/octet-stream
 Content-Transfer-Encoding: binary
 
 *** picture data ***
 
 --roPK9J3DoG4SCZWP6etiDuJ97h-zeNAph
 
 Note: do not forget to put a blank line between "Content-Transfer-Encoding: binary" and your picture data.
 Response
 The response is a simple JSON-encoded object containing the URL of the new entity
 {"url":"http://www.example.com/gallery3/index.php/rest/item/13"}
 
 */

- (SCZWGalleryRemoteStatusCode)addItemSynchronously:(SCZWGalleryItem *)item 
{
	
	NSDate *startUploadDate = [NSDate date];
	
    cancelled = NO;
    
	NSURL *fullURL = [[NSURL alloc] initWithString:[self url]];

    CFHTTPMessageRef messageRef = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("POST"), (CFURLRef)fullURL, kCFHTTPVersion1_1);

	/*
	 * gf: 2/27/2008: The initial login to a gallery (ZWGallery doLogin) uses NSURLRequest. Since this
	 * connection uses CFHTTPMessage (in order to monitor progress; see below), and since CFHTTPMessage
	 * (apparently) doesn't handle user@pass in URLs automagically, we may need to add authentication
	 * credentials. We have to pull them out of the URL (if they're there).
	 *
	 * Note the warning in the CF Network Programming Guide: "Do not apply credentials to the HTTP request
	 * before receiving a server challenge. The server may have changed since the last time you authenticated
	 * and you could create a security risk." Unfortunately, doing this right would require a more elaborate
	 * reworking of the upload loop (below) than I have time or understanding to create.
	 */
	NSString *user = [fullURL user];
	NSString *password = [fullURL password];
	//NSLog(@"addItemSynchronously: user=%@, password=%@", user, password);
	if (user != nil) {
		//NSLog(@"addItemSynchronously: adding authentication");
		Boolean result = CFHTTPMessageAddAuthentication(messageRef,		// request
														nil,			// authenticationFailureResponse
														(CFStringRef)user,
														(CFStringRef)password,
														kCFHTTPAuthenticationSchemeBasic,
														FALSE);			// forProxy
		if (!result) {
			NSLog(@"addItemSynchronously: failed to add authentication!");
		}
	}
	
	
	NSString *requestkey = [gallery requestkey];
	//NSLog(@"addItemSynchronously: album url=%@, requestkey=%@", fullURL,  requestkey);
	//NSLog(@"addItemSynchronously: album url=%@", fullURL);

	CFHTTPMessageSetHeaderFieldValue(messageRef, CFSTR("X-Gallery-Request-Method"), CFSTR("post"));
	CFHTTPMessageSetHeaderFieldValue(messageRef, CFSTR("X-Gallery-Request-Key"), (CFStringRef)[NSString stringWithFormat:@"%@", requestkey]);
    
    NSString *boundary = @"--------SCiPhotoToGallery012nklfad9s0an3flakn3lkghkdshlafk3ln2lghroqyoi-----";
    // the actual boundary lines can to start with an extra 2 hyphens, so we'll make a string to hold that too
    NSString *boundaryNL = [[@"--" stringByAppendingString:boundary] stringByAppendingString:@"\r\n"];
    NSData *boundaryData = [NSData dataWithData:[boundaryNL dataUsingEncoding:NSASCIIStringEncoding]];
    
    CFHTTPMessageSetHeaderFieldValue(messageRef, CFSTR("Content-Type"), (CFStringRef)[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]);
    CFHTTPMessageSetHeaderFieldValue(messageRef, CFSTR("User-Agent"), CFSTR("iPhotoToGallery3 0.1"));
    CFHTTPMessageSetHeaderFieldValue(messageRef, CFSTR("Connection"), CFSTR("close"));
    
    // don't forget the cookies!
    NSHTTPCookieStorage *cookieStore = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSDictionary *cookiesInfo = [NSHTTPCookie requestHeaderFieldsWithCookies:[cookieStore cookiesForURL:[gallery fullURL]]];
    CFHTTPMessageSetHeaderFieldValue(messageRef, CFSTR("Cookie"), (CFStringRef)[cookiesInfo objectForKey:@"Cookie"]);
    
    NSMutableData *requestData = [NSMutableData data];
	[requestData appendData:boundaryData];

	// photo name
	NSString *itemname = nil;
	if ([item caption]) {
		itemname = [item caption];
	} else {
		itemname = [item filename];
	}
	
	// Create SBJSON object to write JSON
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	[dict setObject:[item filename] forKey:@"name"];
	[dict setObject:itemname forKey:@"title"];
	if ([item description] != nil) {
		[dict setObject:[item description] forKey:@"description"];
	}
	[dict setObject:@"photo" forKey:@"type"];

	SBJsonWriter *jsonwriter = [SBJsonWriter new];
	NSString *jsonParams = [jsonwriter stringWithObject:dict];
    
	[requestData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"entity\"\r\nContent-Type: text/plain; charset=UTF-8\r\nContent-Transfer-Encoding: 8bit\r\n\r\n%@\r\n\r\n", jsonParams] dataUsingEncoding:[gallery sniffedEncoding]]];
    
    // the file
    [requestData appendData:boundaryData];
	[requestData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\nContent-Type: %@\r\n\r\n", [item filename], [item imageType]] dataUsingEncoding:[gallery sniffedEncoding]]];
    [requestData appendData:[item data]];
    // closing
    [requestData appendData:[@"\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    [requestData appendData:boundaryData];
    
    CFHTTPMessageSetBody(messageRef, (CFDataRef)requestData);
    
    CFReadStreamRef readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, messageRef);
    // make sure the proxy information is set on the stream
    CFDictionaryRef proxyDict = SCDynamicStoreCopyProxies(NULL);
    CFReadStreamSetProperty(readStream, kCFStreamPropertyHTTPProxy, proxyDict);
    CFReadStreamSetProperty(readStream, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue);
    
    CFReadStreamOpen(readStream);

    // TODO: change this from polling to using callbacks (polling was just plain easier...)
    // I have to use CFNetwork so I can get some information on upload progress
    BOOL done = FALSE;
    unsigned long bytesSentSoFar = 0;
    NSMutableData *data = [NSMutableData data];
    while (!done && !cancelled) {
		// commented to speed up upload time
       // [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        
        if (CFReadStreamHasBytesAvailable(readStream)) {
            UInt8 buf[BUFSIZE];
            CFIndex bytesRead = CFReadStreamRead(readStream, buf, BUFSIZE);
            if (bytesRead < 0) {
                // uh-oh - this returns without releasing our CF objects
				NSLog(@"addItemSynchronously: photo '%@' upload to album %@ error bytes read < 0", itemname, fullURL);
                return SCZW_GALLERY_UNKNOWN_ERROR;
            } else if (bytesRead == 0) {
                done = YES;
            } else {
                [data appendBytes:buf length:bytesRead];
            }
        }
        
        if (CFReadStreamGetStatus(readStream) == kCFStreamStatusAtEnd || CFReadStreamGetStatus(readStream) == kCFStreamStatusClosed)
            done = YES;
        
        // This is why we're using CFStream - we need to find out how much we've uploaded at any given point.
        CFNumberRef bytesWrittenRef = (CFNumberRef)CFReadStreamCopyProperty(readStream, kCFStreamPropertyHTTPRequestBytesWrittenCount);
        unsigned long bytesWritten = [(NSNumber *)bytesWrittenRef unsignedLongValue];
        CFRelease(bytesWrittenRef);
        
        if (bytesSentSoFar != bytesWritten) {
            bytesSentSoFar = bytesWritten;
            [delegate album:self item:item updateBytesSent:bytesWritten]; 
        }
	  
    }
    
    CFRelease(messageRef);
    CFRelease(readStream);
    
    if (cancelled) {
		NSLog(@"addItemSynchronously: photo '%@' upload to album %@ canceled", itemname, fullURL);
        return SCZW_GALLERY_OPERATION_DID_CANCEL;
    }
		
    NSDictionary *galleryResponse = [[self gallery] parseResponseData:data];
    if (galleryResponse == nil) {
		NSLog(@"addItemSynchronously: photo '%@' upload to album %@ failed, response=%@", itemname, fullURL, data);
        return SCZW_GALLERY_PROTOCOL_ERROR;
    }
    
    SCZWGalleryRemoteStatusCode status = (SCZWGalleryRemoteStatusCode)[[galleryResponse objectForKey:@"statusCode"] intValue];
    
    [items addObject:item];
    

	NSDate *endUploadDate = [NSDate date];
	
	NSTimeInterval difference = [endUploadDate timeIntervalSinceDate:startUploadDate];
	NSLog(@"addItemSynchronously: upload runtime: %f ,  photo added url=%@", difference, galleryResponse);
	
	/*
	 addItemSynchronously: photo added url={
		url = "http://lescoste.net/gallery3/index.php/rest/item/5340";
	}
	*/
	
	if (canAddTags) {
		// add tags
		NSArray * photoTags = [item keywords];
		
		NSMutableDictionary *galleryTags = [[self gallery] tags];
		
		for (NSString *tag in photoTags) {
			// if image tags not in gallery : add them
			if ([galleryTags objectForKey:tag] == nil) {
				// add tag
				[[self gallery] doCreateTagWithName:tag];	
			}
			NSString * tagUrl = [galleryTags objectForKey:tag];
			NSString * photoUrl = [galleryResponse objectForKey:@"url"];
			
			// add tags to image
			status = [[self gallery] doLinkTag:tagUrl withPhoto:photoUrl];		
		}
	}
	
    return status;
}

@end
