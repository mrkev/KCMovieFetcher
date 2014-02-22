//
//  KCMovieFetcher.h
//  Watch
//
//  Created by Kevin on 01/04/13.
//  Copyright (c) 2013. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KCMovieFetcherDelegate;

@interface KCMovieFetcher : NSObject

@property (assign, nonatomic) id<KCMovieFetcherDelegate> delegate;
@property NSDictionary *movieTags;

// Search
- (void)searchOMDBAPIWithQuery:(NSString *)query;
- (void)searchiTunesWithQuery:(NSString *)query;

// Information
- (void)fetchAPIDataForMovieTitle:(NSString *)title year:(NSString *)year imdbID:(NSString *)imdbid;;
- (void)fetchiTunesDataForMovieTitle:(NSString *)title year:(NSString *)year;

// URL Builders
+ (NSURL *)OMDBAPISearchURLWithQuery:(NSString *)query;
+ (NSURL *)OMDBAPIMovieURLForTitle:(NSString *)title year:(NSString *)year imdbid:(NSString *)imdbid;

@end

@protocol KCMovieFetcherDelegate <NSObject>

@optional

//
// Results of search
//

- (void)movieFetcherDidRecieveOMDBAPISearchResults:(NSDictionary *)results;
- (void)movieFetcherDidRecieveiTunesSearchResults:(NSDictionary *)results;

- (void)movieFetcherDidRecievePosterImageData:(NSData *)data forMovieTags:(NSDictionary *)movie;

// Data loaded: send tags do diferentiate it from any other
// results, as the whole process is async and more than one
// fetch could be going on at a time
- (void)movieFetcherDidLoadDataForMovieTags:(NSDictionary *)movie
                   inDictionary:(NSDictionary *)info;

// Data load failed
- (void)movieFetcherDidFailToLoadAPIDataForMovieTags:(NSDictionary *)movieTags
                            withError:(NSError *)error;

// Poster image loaded
- (void)movieFetcherDidLoadiTunesDataForMovieTags:(NSDictionary *)movie
                          inDictionary:(NSDictionary *)info;

// Poster image load failed
- (void)movieFetcherDidFailToLoadiTunesDataForMovieTags:(NSDictionary *)movieTags
                            withError:(NSError *)error;

@end