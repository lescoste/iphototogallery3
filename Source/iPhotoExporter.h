//
//  iPhotoExporter.h
//
//  These are the classes and protocols that will be interesting to us when we're running inside iPhoto.
//  If I remember correctly these were class-dump'd from iPhoto 2, and have been stable since then (with
//  one minor exception.) Thanks Apple!
//

#import <Foundation/Foundation.h>

/*
 File:       ExportImageProtocol.h
 
 Contains:   iPhoto Plug-ins interfaces: Protocol for image exporting
 
 Version:    Technology: iPhoto
 Release:    1.0
 
 Copyright:  © 2002-2007 by Apple Inc. All rights reserved.
 
 Bugs?:      For bug reports, consult the following page on
 the World Wide Web:
 
 http://developer.apple.com/bugreporter/
 */

typedef enum
{
	EQualityLow,
	EQualityMed,
	EQualityHigh,
	EQualityMax
} ExportQuality;

typedef enum
{
	EMNone, // 0000
	EMEXIF, // 0001
	EMIPTC, // 0010
	EMBoth  // 0011
} ExportMetadata;

typedef struct
{
	OSType			format;
	ExportQuality	quality;
	float			rotation;
	unsigned		width;
	unsigned		height;
	ExportMetadata	metadata;
} ImageExportOptions;

//exif metadata access keys
#define kIPExifDateDigitized @"DateDigitized"
#define kIPExifCameraModel @"CameraModel"
#define kIPExifShutter @"Shutter"
#define kIPExifAperture @"Aperture"
#define kIPExifMaxAperture @"MaxAperture"
#define kIPExifExposureBias @"ExposureBias"
#define kIPExifExposure @"Exposure"
#define kIPExifExposureIndex @"ExposureIndex"
#define kIPExifFocalLength @"FocalLength"
#define kIPExifDistance @"Distance"
#define kIPExifSensing @"Sensing"
#define kIPExifLightSource @"LightSource"
#define kIPExifFlash @"Flash"
#define kIPExifMetering @"Metering"
#define kIPExifBrightness @"Brightness"
#define kIPExifISOSpeed @"ISOSpeed"

//tiff metadata access keys
#define kIPTiffImageWidth @"ImageWidth"
#define kIPTiffImageHeight @"ImageHeight"
#define kIPTiffOriginalDate @"OriginalDate"
#define kIPTiffDigitizedDate @"DigitizedDate"
#define kIPTiffFileName @"FileName"
#define kIPTiffFileSize @"FileSize"
#define kIPTiffModifiedDate @"ModifiedDate"
#define kIPTiffImportedDate @"ImportedDate"
#define kIPTiffCameraMaker @"CameraMaker"
#define kIPTiffCameraModel @"CameraModel"
#define kIPTiffSoftware @"Software"

@protocol ExportImageProtocol

//------------------------------------------------------------------------------
// Access to images
//------------------------------------------------------------------------------
- (unsigned)imageCount;
- (NSSize)imageSizeAtIndex:(unsigned)index;
- (OSType)imageFormatAtIndex:(unsigned)index;
- (OSType)originalImageFormatAtIndex:(unsigned)index;
- (BOOL)originalIsRawAtIndex:(unsigned)index;
- (BOOL)originalIsMovieAtIndex:(unsigned)index;
- (NSString *)imageTitleAtIndex:(unsigned)index;
- (NSString *)imageCommentsAtIndex:(unsigned)index;
- (float)imageRotationAtIndex:(unsigned)index;
- (NSString *)imagePathAtIndex:(unsigned)index;
- (NSString *)sourcePathAtIndex:(unsigned)index;
- (NSString *)thumbnailPathAtIndex:(unsigned)index;
- (NSString *)imageFileNameAtIndex:(unsigned)index;
- (BOOL)imageIsEditedAtIndex:(unsigned)index;
- (BOOL)imageIsPortraitAtIndex:(unsigned)index;
- (float)imageAspectRatioAtIndex:(unsigned)index;
- (unsigned long long)imageFileSizeAtIndex:(unsigned)index;
- (NSDate *)imageDateAtIndex:(unsigned)index;
- (int)imageRatingAtIndex:(unsigned)index;
- (NSDictionary *)imageTiffPropertiesAtIndex:(unsigned)index;
- (NSDictionary *)imageExifPropertiesAtIndex:(unsigned)index;
- (NSArray *)imageKeywordsAtIndex:(unsigned)index;
- (NSArray *)albumsOfImageAtIndex:(unsigned)index;

- (NSString *)getExtensionForImageFormat:(OSType)format;
- (OSType)getImageFormatForExtension:(NSString *)extension;

//------------------------------------------------------------------------------
// Access to albums
//------------------------------------------------------------------------------
- (unsigned)albumCount; //total number of albums
- (NSString *)albumNameAtIndex:(unsigned)index; //name of album at index
- (NSString *)albumMusicPathAtIndex:(unsigned)index;
- (NSString *)albumCommentsAtIndex:(unsigned)index;
- (unsigned)positionOfImageAtIndex:(unsigned)index inAlbum:(unsigned)album;

//------------------------------------------------------------------------------
// Access to export controller's GUI
//------------------------------------------------------------------------------
- (id)window;
- (void)enableControls;
- (void)disableControls;

- (void)clickExport;
- (void)startExport;
- (void)cancelExportBeforeBeginning;

- (NSString *)directoryPath;
- (unsigned)sessionID;

- (BOOL)exportImageAtIndex:(unsigned)index dest:(NSString *)dest options:(ImageExportOptions *)options;
- (NSSize)lastExportedImageSize;

//------------------------------------------------------------------------------
@end

@interface ExportController:NSObject
{
    id mWindow;
    id mExportView;
    id mExportButton;
    id mImageCount;
    id *mExportMgr;
    id *mCurrentPluginRec;
    id *mProgressController;
    char mCancelExport;
    NSTimer *mTimer;
    NSString *mDirectoryPath;
}

- (void)awakeFromNib;
- (void)dealloc;
- currentPlugin;
- currentPluginRec;
- (void)setCurrentPluginRec:fp12;
- directoryPath;
- (void)setDirectoryPath:fp12;
- (void)show;
- (void)_openPanelDidEnd:fp12 returnCode:(int)fp16 contextInfo:(void *)fp20;
- panel:fp12 userEnteredFilename:fp16 confirmed:(char)fp20;
- (char)panel:fp12 shouldShowFilename:fp16;
- (char)panel:fp12 isValidFilename:fp16;
- (char)filesWillFitOnDisk;
- (void)export:fp12;
- (void)_exportThread:fp12;
- (void)_exportProgress:fp12;
- (void)startExport:fp12;
- (void)finishExport;
- (void)cancelExport;
- (void)cancel:fp12;
- (void)enableControls;
- window;
- (void)disableControls;
- (void)tabView:fp12 willSelectTabViewItem:fp16;
- (void)tabView:fp12 didSelectTabViewItem:fp16;
- (void)selectExporter:fp12;
- exportView;
- (char)_hasPlugins;
- (void)_resizeExporterToFitView:fp12;
- (void)_updateImageCount;

@end

@interface ExportMgr:NSObject <ExportImageProtocol>
{
    id *mDocument;
    NSMutableArray *mExporters;
    id *mExportAlbum;
    NSArray *mSelection;
    NSArray *mSelectedAlbums;
    ExportController *mExportController;
} 

+ exportMgr;
+ exportMgrNoAlloc;
- init;
- (void)dealloc;
- (void)releasePlugins;
- (void)setExportController:fp12;
- (ExportController*)exportController;
- (void)setDocument:fp12;
- document;
- (void)updateDocumentSelection;
- (unsigned int)count;
- recAtIndex:(unsigned int)fp12;
- (void)scanForExporters;
- (unsigned int)imageCount;
- (char)imageIsPortraitAtIndex:(unsigned int)fp12;
- imagePathAtIndex:(unsigned int)fp12;
- (struct _NSSize)imageSizeAtIndex:(unsigned int)fp16;
- (unsigned int)imageFormatAtIndex:(unsigned int)fp12;
- imageCaptionAtIndex:(unsigned int)fp12;
- thumbnailPathAtIndex:(unsigned int)fp12;
- imageDictionaryAtIndex:(unsigned int)fp12;
- (float)imageAspectRatioAtIndex:(unsigned int)fp12;
- selectedAlbums;
- albumComments;
- albumName;
- albumMusicPath;
- (unsigned int)albumCount;
- (unsigned int)albumPositionOfImageAtIndex:(unsigned int)fp12;
- imageRecAtIndex:(unsigned int)fp12;
- currentAlbum;
- (void)enableControls;
- (void)disableControls;
- window;
- (void)clickExport;
- (void)startExport;
- (void)cancelExport;
- (void)cancelExportBeforeBeginning;
- directoryPath;
- temporaryDirectory;
- (char)doesFileExist:fp12;
- (char)doesDirectoryExist:fp12;
- (char)createDir:fp12;
- uniqueSubPath:fp12 child:fp16;
- makeUniquePath:fp12;
- makeUniqueFilePath:fp12 extension:fp16;
- makeUniqueFileNameWithTime:fp12;
- (char)makeFSSpec:fp12 spec:(struct FSSpec *)fp16;
- pathForFSSpec:fp12;
- (char)getFSRef:(struct FSRef *)fp12 forPath:fp16 isDirectory:(char)fp20;
- pathForFSRef:(struct FSRef *)fp12;
- (unsigned long)countFiles:fp12 descend:(char)fp16;
- (unsigned long)countFilesFromArray:fp12 descend:(char)fp16;
- (unsigned long long)sizeAtPath:fp12 count:(unsigned long *)fp16 physical:(char)fp20;
- (char)isAliasFileAtPath:fp12;
- pathContentOfAliasAtPath:fp12;
- stringByResolvingAliasesInPath:fp12;
- (char)ensurePermissions:(unsigned long)fp12 forPath:fp16;
- validFilename:fp12;
- getExtensionForImageFormat:(unsigned int)fp12;
- (unsigned int)getImageFormatForExtension:fp12;
- (struct OpaqueGrafPtr *)uncompressImage:fp12 size:(struct _NSSize)fp16 pixelFormat:(unsigned int)fp24 rotation:(float)fp40 colorProfile:(STR **)fp32;
- (void *)createThumbnailer;
- (void *)retainThumbnailer:(void *)fp12;
- (void *)autoreleaseThumbnailer:(void *)fp12;
- (void)releaseThumbnailer:(void *)fp12;
- (void)setThumbnailer:(void *)fp12 maxBytes:(unsigned int)fp16 maxWidth:(unsigned int)fp20 maxHeight:(unsigned int)fp24;
- (struct _NSSize)thumbnailerMaxBounds:(void *)fp16;
- (void)setThumbnailer:(void *)fp12 quality:(int)fp16;
- (int)thumbnailerQuality:(void *)fp12;
- (void)setThumbnailer:(void *)fp12 rotation:(float)fp40;
- (float)thumbnailerRotation:(void *)fp12;
- (void)setThumbnailer:(void *)fp12 outputFormat:(unsigned int)fp16;
- (unsigned int)thumbnailerOutputFormat:(void *)fp12;
- (void)setThumbnailer:(void *)fp12 outputExtension:fp16;
- thumbnailerOutputExtension:(void *)fp12;
- (char)thumbnailer:(void *)fp12 createThumbnail:fp16 dest:fp20;
- (struct _NSSize)lastImageSize:(void *)fp16;
- (struct _NSSize)lastThumbnailSize:(void *)fp16;

@end


