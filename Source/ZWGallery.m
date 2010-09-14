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
#import "ZWGallery.h"
#import "ZWGalleryAlbum.h"
#import "NSString+misc.h"
#import "ZWURLConnection.h"
#import "InterThreadMessaging.h"
#import "ZWMutableURLRequest.h"

@interface ZWGallery (PrivateAPI)
- (void)loginThread:(NSDictionary *)threadDispatchInfo;
- (ZWGalleryRemoteStatusCode)doLogin;

- (void)getAlbumsThread:(NSDictionary *)threadDispatchInfo;
- (ZWGalleryRemoteStatusCode)doGetAlbums;

- (void)createAlbumThread:(NSDictionary *)threadDispatchInfo;
- (ZWGalleryRemoteStatusCode)doCreateAlbumWithName:(NSString *)name title:(NSString *)title summary:(NSString *)summary parent:(ZWGalleryAlbum *)parent;

@end

@implementation ZWGallery

#pragma mark Object Life Cycle

- (id)init {
    return self;
}

- (id)initWithURL:(NSURL*)newUrl username:(NSString*)newUsername {
    url = [newUrl retain];
    fullURL = [[NSURL alloc] initWithString:[[url absoluteString] stringByAppendingString:@"rest"]];
    username = [newUsername retain];
    delegate = self;
    loggedIn = FALSE;
    majorVersion = 0;
    minorVersion = 0;
    type = GalleryTypeG1;
    
    return self;
}

- (id)initWithDictionary:(NSDictionary*)dictionary {
    [self initWithURL:[NSURL URLWithString:[dictionary objectForKey:@"url"]] 
             username:[dictionary objectForKey:@"username"]];
    
    NSNumber *typeNumber = [dictionary objectForKey:@"type"];
    if (typeNumber)
        type = [typeNumber intValue];
    
    return self;
}

+ (ZWGallery*)galleryWithURL:(NSURL*)newUrl username:(NSString*)newUsername {
    return [[[ZWGallery alloc] initWithURL:newUrl username:newUsername] autorelease];
}

+ (ZWGallery*)galleryWithDictionary:(NSDictionary*)dictionary {
    return [[[ZWGallery alloc] initWithDictionary:dictionary] autorelease];
}

- (void)dealloc
{
    [url release];
    [requestkey release];
    [username release];
    [password release];
    [albums release];
    [jsonalbums release];
    [lastCreatedAlbumName release];
    
    [super dealloc];
}

#pragma mark NSComparisonMethods

- (BOOL)isEqual:(id)gal
{
    return ([username isEqual:[gal username]] && [[url absoluteString] isEqual:[[gal url] absoluteString]]);
}

- (NSComparisonResult)compare:(id)gal
{
    return [[self identifier] caseInsensitiveCompare:[gal identifier]];
}

#pragma mark Accessors

- (void)setDelegate:(id)newDelegate {
    delegate = newDelegate;
}

- (id)delegate {
    return delegate;
}

- (void)setPassword:(NSString*)newPassword {
    [newPassword retain];
    [password release];
    password = newPassword;
}

- (NSURL*)url {
    return url;
}

- (NSURL*)fullURL {
    return fullURL;
}

- (NSString*)identifier {
    return [NSString stringWithFormat:@"%@%@ (%@)", [url host], [url path], username];
}

- (NSString*)urlString {
    return [url absoluteString];
}

//X-Gallery-Request-Key: 1114d4023d89b15ce10a20ba4333eff7
- (NSString*)requestkey {
    return requestkey;
}

- (NSString*)username {
    return username;
}

- (int)majorVersion {
    return majorVersion;
}

- (int)minorVersion {
    return minorVersion;
}

- (BOOL)loggedIn {
    return loggedIn;
}

- (NSArray*)albums {
    return albums;
}

- (NSMutableArray*)jsonalbums {
    return jsonalbums;
}


- (NSDictionary*)infoDictionary {
    return [NSDictionary dictionaryWithObjectsAndKeys:
			username, @"username",
			[url absoluteString], @"url",
			[NSNumber numberWithInt:(int)type], @"type",
			nil];
}

- (BOOL)isGalleryV2 {
	return ([self type] == GalleryTypeG2 || [self type] == GalleryTypeG2XMLRPC);
}

- (ZWGalleryType)type {
    return type;
}

- (NSString *)lastCreatedAlbumName
{
    return lastCreatedAlbumName;
}

- (NSStringEncoding)sniffedEncoding
{
    return sniffedEncoding;
}

#pragma mark Actions

- (void)cancelOperation
{
    if (currentConnection && ![currentConnection isCancelled]) {
        [currentConnection cancel];
    }
}

- (void)login {
    NSDictionary *threadDispatchInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSThread currentThread], @"CallingThread",
										nil];
    [NSThread detachNewThreadSelector:@selector(loginThread:) toTarget:self withObject:threadDispatchInfo];
}

- (void)logout {
    loggedIn = FALSE;
}

- (void)createAlbumWithName:(NSString *)name title:(NSString *)title summary:(NSString *)summary parent:(ZWGallery *)parent
{
    if (parent == nil) 
        (id)parent = (id)[NSNull null];
	
    NSDictionary *threadDispatchInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										name, @"AlbumName",
										title, @"AlbumTitle",
										summary, @"AlbumSummary",
										parent, @"AlbumParent",
										[NSThread currentThread], @"CallingThread",
										nil];
	
    [NSThread detachNewThreadSelector:@selector(createAlbumThread:) toTarget:self withObject:threadDispatchInfo];
}

- (void)getAlbums {
    NSDictionary *threadDispatchInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSThread currentThread], @"CallingThread",
										nil];
    [NSThread detachNewThreadSelector:@selector(getAlbumsThread:) toTarget:self withObject:threadDispatchInfo];
}

#pragma mark Helpers

/*
 album data = 
 [{"url":"http:\/\/lescoste.net\/gallery3\/rest\/item\/1",
 "entity":{
 "id":"1",
 "captured":null,
 "created":"1282991704",
 "description":"",
 "height":null,
 "level":"1",
 "mime_type":null,
 "name":null,
 "owner_id":"2",
 "rand_key":null,
 "resize_height":null,
 "resize_width":null,
 "slug":"",
 "sort_column":"weight",
 "sort_order":"ASC",
 "thumb_height":"113",
 "thumb_width":"150",
 "title":"Gallery Lescoste.net",
 "type":"album",
 "updated":"1283283475",
 "view_count":"6656",
 "width":null,
 "view_1":"1",
 "view_2":"1",
 "view_3":"1",
 "view_4":"1",
 "view_5":"1",
 "view_6":"1",
 "album_cover":"http:\/\/lescoste.net\/gallery3\/rest\/item\/176",
 "thumb_url":"http:\/\/lescoste.net\/gallery3\/var\/thumbs\/\/.album.jpg?m=1283283475",
 "can_edit":false},
 "relationships":{
 "comments":{"url":"http:\/\/lescoste.net\/gallery3\/rest\/item_comments\/1"},
 "tags":{"url":"http:\/\/lescoste.net\/gallery3\/rest\/item_tags\/1","members":[]}
 },
 "members":["http:\/\/lescoste.net\/gallery3\/rest\/item\/2",
 "http:\/\/lescoste.net\/gallery3\/rest\/item\/5",
 "http:\/\/lescoste.net\/gallery3\/rest\/item\/4",
 "http:\/\/lescoste.net\/gallery3\/rest\/item\/3",
 "http:\/\/lescoste.net\/gallery3\/rest\/item\/6"]}]
 */	

- (NSArray*)parseResponseData:(NSData*)responseData {
	NSString *response = [[[NSString alloc] initWithData:responseData encoding:[self sniffedEncoding]] autorelease];
    
    if (response == nil) {
        NSLog(@"Could not convert response data into a string with encoding: %i", [self sniffedEncoding]);
        return nil;
    }
    // Create SBJSON object to parse JSON
	SBJsonParser *parser = [SBJsonParser new];
	//[parser initialize];
    
	// parse the JSON string into an object - assuming json_string is a NSString of JSON data
	NSArray *dict = [parser objectWithString:response error:nil];
	//NSLog ( @"parseResponseData dict = %@", dict );
	
	return dict;
}

- (ZWGalleryRemoteStatusCode)getandparseAlbums:(NSArray*)members {
	
	int i =0;
	int nbmembers = [members count];
	NSLog ( @"getandparseAlbums nbmembers size : %d", nbmembers );
	while (i < nbmembers) {
		
		// go get 5 members data in one request
		NSString *requestString = @"type=album&output=json&scope=all&urls=[";
		int j =0;
		for (j=0; j < 10 && i < nbmembers ; j++) {
			NSString *member = [members objectAtIndex:i];
			if (j>0) {
				requestString = [requestString stringByAppendingString:@","];		
			}
			requestString = [requestString stringByAppendingString:@"\""];		
			requestString = [requestString stringByAppendingString:member];		
			requestString = [requestString stringByAppendingString:@"\""];		
			i++;
		}
		requestString = [requestString stringByAppendingString:@"]" ];
		
		NSString* escapedUrlString = [requestString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
		
		
		fullURL = [[NSURL alloc] initWithString:[[url absoluteString] stringByAppendingString:@"rest/items?"]];
		NSURL* fullReqURL = [[NSURL alloc] initWithString:[[fullURL absoluteString] stringByAppendingString:escapedUrlString]];
		
		NSLog ( @"fullReqURL  = %@", [fullReqURL absoluteString] );
		
		NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:fullReqURL
																  cachePolicy:NSURLRequestReloadIgnoringCacheData
															  timeoutInterval:60.0];
		[theRequest setValue:@"iPhotoToGallery" forHTTPHeaderField:@"User-Agent"];
		
		NSLog ( @"The current date and time is: %@ ; doGetAlbums requestkey  = %@", [NSDate date], requestkey );
		
		[theRequest setHTTPMethod:@"GET"];
		[theRequest setValue:@"get" forHTTPHeaderField:@"X-Gallery-Request-Method"];
		[theRequest setValue:requestkey forHTTPHeaderField:@"X-Gallery-Request-Key"];
		
		
		currentConnection = [ZWURLConnection connectionWithRequest:theRequest];
		while ([currentConnection isRunning]) 
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
		
		if ([currentConnection isCancelled]) 
			return ZW_GALLERY_OPERATION_DID_CANCEL;
		
		// reponse from server
		
		NSData *data = [currentConnection data];
		
		if (data == nil) 
			return ZW_GALLERY_COULD_NOT_CONNECT;
		
		NSArray *galleryResponse = [[self parseResponseData:data] retain];
		if (galleryResponse == nil) 
			return ZW_GALLERY_PROTOCOL_ERROR;
		
		// for each album, get sub albums
		for (NSDictionary *dict in galleryResponse) {
			
			NSDictionary *entity = [dict objectForKey:@"entity"];
			NSNumber *canEdit = [entity objectForKey:@"can_edit"];
			
			if ([canEdit intValue] == 1) {
				[jsonalbums addObject:[dict retain]];
				
				NSString *title = [entity objectForKey:@"title"];
				NSLog ( @"getandparseAlbums add album : %@ ", title );
				NSLog ( @"getandparseAlbums jsonalbums size : %d", [jsonalbums count] );

			}
		}
	}
	NSLog ( @"getandparseAlbums end");
	
	
	return GR_STAT_SUCCESS;
}


- (NSString *)formNameWithName:(NSString *)paramName
{
    // Gallery 1 names don't need mangling
    if (![self isGalleryV2]) 
        return paramName;
    
    // For some reason userfile is just changed to g2_userfile
    if ([paramName isEqualToString:@"userfile"])
        return @"g2_userfile";
    
    // All other G2 params are mangled like this:
    return [NSString stringWithFormat:@"g2_form[%@]", paramName];
}

#pragma mark Threads

- (void)loginThread:(NSDictionary *)threadDispatchInfo {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [NSThread prepareForInterThreadMessages];
	
    NSThread *callingThread = [threadDispatchInfo objectForKey:@"CallingThread"];
    
    ZWGalleryRemoteStatusCode status = [self doLogin];
    
    if (status == GR_STAT_SUCCESS)
        [delegate performSelector:@selector(galleryDidLogin:) 
                       withObject:self 
                         inThread:callingThread];
    else
        [delegate performSelector:@selector(gallery:loginFailedWithCode:) 
                       withObject:self 
                       withObject:[NSNumber numberWithInt:status] 
                         inThread:callingThread];
    
    [pool release];
}

- (ZWGalleryRemoteStatusCode)doLogin
{
    // remove the cookies sent to the gallery (the login function ain't so smart)
    NSHTTPCookieStorage *cookieStore = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [cookieStore cookiesForURL:fullURL];
    id cookie;
    NSEnumerator *enumerator = [cookies objectEnumerator];
    while (cookie = [enumerator nextObject]) {
        [cookieStore deleteCookie:cookie];
    }
    
    
    // Default to UTF-8
    sniffedEncoding = NSUTF8StringEncoding;
    
    // Now try to log in 
	// try logging into Gallery v3
	fullURL = [[NSURL alloc] initWithString:[[url absoluteString] stringByAppendingString:@"rest"]];
	
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:fullURL
															  cachePolicy:NSURLRequestReloadIgnoringCacheData
														  timeoutInterval:60.0];
	[theRequest setValue:@"iPhotoToGallery" forHTTPHeaderField:@"User-Agent"];
	// X-Gallery-Request-Method: post
	[theRequest setValue:@"post" forHTTPHeaderField:@"X-Gallery-Request-Method"];
	
	[theRequest setHTTPMethod:@"POST"];
	
	NSString *requestString = [NSString stringWithFormat:@"user=%s&password=%s",
							   [[username stringByEscapingURL] UTF8String], [[password stringByEscapingURL] UTF8String]];
	NSData *requestData = [requestString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	[theRequest setHTTPBody:requestData];
	
	currentConnection = [ZWURLConnection connectionWithRequest:theRequest];
	while ([currentConnection isRunning]) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
	}
	
	if ([currentConnection isCancelled]) 
		return ZW_GALLERY_OPERATION_DID_CANCEL;
	
	NSData *data = [currentConnection data];
	NSURLResponse *response = [currentConnection response];
	
	if (data == nil) 
		return ZW_GALLERY_COULD_NOT_CONNECT;
	
    NSString *rzkey = [[[NSString alloc] initWithData:data encoding:[self sniffedEncoding]] autorelease];
	// remove quotes around key
    rzkey = [rzkey substringFromIndex:1];
	int l = [rzkey length] - 1;
    rzkey = [rzkey substringToIndex:l];
    requestkey = [rzkey retain];
	
	
	if ([(NSHTTPURLResponse *)response statusCode] == 200 ) {
		// we successfully logged into a G2
		type = GalleryTypeG2;
        loggedIn = YES;
		
		if (requestkey == nil) {
			NSLog(@"Could not read request key with encoding: %i", [self sniffedEncoding]);
			return GR_STAT_PASSWD_WRONG;
		}
		
		NSLog ( @"The current date and time is: %@ ; requestkey = %@", [NSDate date], requestkey );
		
		return GR_STAT_SUCCESS;
	}
	if ([(NSHTTPURLResponse *)response statusCode] == 403 ) {
        return GR_STAT_PASSWD_WRONG;
	}    
	NSLog ( @"The current date and time is: %@ ; error = %d", [NSDate date], [(NSHTTPURLResponse *)response statusCode] );
    
    return ZW_GALLERY_UNKNOWN_ERROR;
}

- (void)getAlbumsThread:(NSDictionary *)threadDispatchInfo {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    [NSThread prepareForInterThreadMessages];
	
    NSThread *callingThread = [threadDispatchInfo objectForKey:@"CallingThread"];
    
    ZWGalleryRemoteStatusCode status = [self doGetAlbums];
    
    if (status == GR_STAT_SUCCESS)
        [delegate performSelector:@selector(galleryDidGetAlbums:) 
                       withObject:self
                         inThread:callingThread];
    else
        [delegate performSelector:@selector(gallery:getAlbumsFailedWithCode:) 
                       withObject:self 
                       withObject:[NSNumber numberWithInt:status] 
                         inThread:callingThread];
	
    [pool release];
}

- (ZWGalleryRemoteStatusCode)doGetAlbums
{
	
	// store all json albums from gallery
	jsonalbums = [[[NSMutableArray alloc] init] retain];                                     
	
	// initial album
	NSString *requestString = @"type=album&output=json&scope=all";
	NSString* escapedUrlString = [requestString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	fullURL = [[NSURL alloc] initWithString:[[url absoluteString] stringByAppendingString:@"rest/item/1?"]];
	NSURL* fullReqURL = [[NSURL alloc] initWithString:[[fullURL absoluteString] stringByAppendingString:escapedUrlString]];
	
	NSLog ( @"The current date and time is: %@ ; fullReqURL  = %@", [NSDate date], [fullReqURL absoluteString] );
	
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:fullReqURL
															  cachePolicy:NSURLRequestReloadIgnoringCacheData
														  timeoutInterval:60.0];
	[theRequest setValue:@"iPhotoToGallery" forHTTPHeaderField:@"User-Agent"];
	
	NSLog ( @"The current date and time is: %@ ; doGetAlbums requestkey  = %@", [NSDate date], requestkey );
	
	[theRequest setHTTPMethod:@"GET"];
	[theRequest setValue:@"get" forHTTPHeaderField:@"X-Gallery-Request-Method"];
	[theRequest setValue:requestkey forHTTPHeaderField:@"X-Gallery-Request-Key"];
	
	
	currentConnection = [ZWURLConnection connectionWithRequest:theRequest];
	while ([currentConnection isRunning]) 
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
	
	if ([currentConnection isCancelled]) 
		return ZW_GALLERY_OPERATION_DID_CANCEL;
	
	// reponse from server
	
	NSData *data = [currentConnection data];
	
	if (data == nil) 
		return ZW_GALLERY_COULD_NOT_CONNECT;
	
	NSDictionary *galleryResponse = [[self parseResponseData:data] retain];
	if (galleryResponse == nil) 
		return ZW_GALLERY_PROTOCOL_ERROR;
	
	NSArray *members = [galleryResponse objectForKey:@"members"];
	
    ZWGalleryRemoteStatusCode status = [self getandparseAlbums:members];
	
	NSLog ( @"doGetAlbums jsonalbums size : %d", [jsonalbums count] );
	
    [albums release];
    albums = nil;
    
    if (status != GR_STAT_SUCCESS)
        return status;
    
    // add the albums to myself here...
    int numAlbums = [jsonalbums count];
    NSMutableArray *galleriesArray = [NSMutableArray array];
    [galleriesArray addObject:[ZWGalleryAlbum albumWithTitle:@"" name:@"" gallery:self]];
    int i;
	
    NSMutableDictionary *galleriesPerUrl = [[NSMutableDictionary alloc] init];
    // first we'll iterate through to create the objects, since we don't know if they'll be in an order
    // where parents will always come before children
    for (i = 0; i < numAlbums; i++) {
		
		NSDictionary *galleryAlbum =  [jsonalbums objectAtIndex:i];
		NSDictionary *entity = [galleryAlbum objectForKey:@"entity"];
		NSString *albumurl = [galleryAlbum objectForKey:@"url"];

        NSString *a_name = [entity objectForKey:@"name"];
        NSString *a_title = [entity objectForKey:@"title"];
		NSString *parent = [entity objectForKey:@"parent"];
		
		[galleriesPerUrl setValue:[NSNumber numberWithInt:i+1] forKey:albumurl];
  
		ZWGalleryAlbum *album = [ZWGalleryAlbum albumWithTitle:a_title name:a_name gallery:self];
		[album setUrl:albumurl];
		[album setParenturl:parent];
		
        // this album will use the delegate of the gallery we're on
        [album setDelegate:[self delegate]];
        
        BOOL a_can_add = YES;
        [album setCanAddItem:a_can_add];
        BOOL a_can_create_sub = YES;
        [album setCanAddSubAlbum:a_can_create_sub];
        [galleriesArray addObject:album];

		NSLog ( @"doGetAlbums added : %d %@", i, a_title );
    }

		
	for (i = 1; i <= numAlbums; i++) {
		ZWGalleryAlbum *album = [galleriesArray objectAtIndex:i];
		
		NSString *parenturl = [album parenturl];
		NSLog ( @"doGetAlbums parent : %d %@", i, parenturl );
		
        if (parenturl != nil) {
			NSNumber *album_parent_id = [galleriesPerUrl objectForKey:parenturl];
			int pid = [album_parent_id intValue];
			if ([parenturl isLike:@"*rest/item/1"]) {
				pid = 0;
			}
			NSLog ( @"doGetAlbums parentid : %d %d", i, pid );

			
			ZWGalleryAlbum *parent = [galleriesArray objectAtIndex:pid];
			
			[album setParent:parent];
			[parent addChild:album];
        }
    }
    albums = [[NSArray alloc] initWithArray:galleriesArray];
    
    return GR_STAT_SUCCESS;
}

- (void)createAlbumThread:(NSDictionary *)threadDispatchInfo {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [NSThread prepareForInterThreadMessages];
    
    NSThread *callingThread = [threadDispatchInfo objectForKey:@"CallingThread"];
    
    ZWGalleryRemoteStatusCode status = [self doCreateAlbumWithName:[threadDispatchInfo objectForKey:@"AlbumName"]
                                                             title:[threadDispatchInfo objectForKey:@"AlbumTitle"]
                                                           summary:[threadDispatchInfo objectForKey:@"AlbumSummary"]
                                                            parent:[threadDispatchInfo objectForKey:@"AlbumParent"]];
    
    if (status == GR_STAT_SUCCESS)
        [delegate performSelector:@selector(galleryDidCreateAlbum:) 
                       withObject:self
                         inThread:callingThread];
    else
        [delegate performSelector:@selector(gallery:createAlbumFailedWithCode:) 
                       withObject:self 
                       withObject:[NSNumber numberWithInt:status] 
                         inThread:callingThread];
    
    [pool release];
}

- (ZWGalleryRemoteStatusCode)doCreateAlbumWithName:(NSString *)name title:(NSString *)title summary:(NSString *)summary parent:(ZWGalleryAlbum *)parent
{    
    NSString *parentName;
    if (parent != nil && ![parent isKindOfClass:[NSNull class]]) 
        parentName = [parent name];
    else 
        parentName = @"0";  // this might break G2, but new G2 albums all have a parent.
	
    ZWMutableURLRequest *theRequest = [ZWMutableURLRequest requestWithURL:fullURL
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                          timeoutInterval:60.0];
    [theRequest setValue:@"iPhotoToGallery" forHTTPHeaderField:@"User-Agent"];
    [theRequest setHTTPMethod:@"POST"];
    [theRequest setEncoding:[self sniffedEncoding]];
    [theRequest setVariation:ZSURLMultipartVariation];
    
    if ([self isGalleryV2]) 
        [theRequest addString:@"remote:GalleryRemote" forName:@"g2_controller"];
    
    [theRequest addString:@"new-album" forName:[self formNameWithName:@"cmd"]];
    [theRequest addString:@"2.3" forName:[self formNameWithName:@"protocol_version"]];
    [theRequest addString:parentName forName:[self formNameWithName:@"set_albumName"]];
    [theRequest addString:name forName:[self formNameWithName:@"newAlbumName"]];
    [theRequest addString:title forName:[self formNameWithName:@"newAlbumTitle"]];
    [theRequest addString:summary forName:[self formNameWithName:@"newAlbumDesc"]];
    
    currentConnection = [ZWURLConnection connectionWithRequest:theRequest];
    while ([currentConnection isRunning]) 
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    if ([currentConnection isCancelled]) 
        return ZW_GALLERY_OPERATION_DID_CANCEL;
    
    NSData *data = [currentConnection data];
    
    if (data == nil) 
        return ZW_GALLERY_COULD_NOT_CONNECT;
    
    NSDictionary *galleryResponse = [self parseResponseData:data];
    if (galleryResponse == nil) 
        return ZW_GALLERY_PROTOCOL_ERROR;
    
    ZWGalleryRemoteStatusCode status = (ZWGalleryRemoteStatusCode)[[galleryResponse objectForKey:@"statusCode"] intValue];
    
    if (status == GR_STAT_SUCCESS) {
        [lastCreatedAlbumName release];
        lastCreatedAlbumName = [[galleryResponse objectForKey:@"album_name"] copy];
    }
    
    // TODO: create an actual ZWGalleryAlbum to return?
    return status;
}

@end
