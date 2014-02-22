//
//  KCMovieFetcher.m
//  Watch
//
//  Created by Kevin on 01/04/13.
//  Copyright (c) 2013 ASPV. All rights reserved.
//

#define kcBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

#define kOMDBAPISearchURLFormat @"http://www.omdbapi.com/?s=%@&tomatoes=true"
#define kOMDBAPIMovieURLFormat  @"a"

#import "KCMovieFetcher.h"

@implementation KCMovieFetcher

#pragma mark -
#pragma Search

/*
 Searches a query on the OMDBAPI on a background thread.
 Once the call completes, sends method to delegate with
 whatever the search returned.
*/

- (void)searchOMDBAPIWithQuery:(NSString *)query
{   dispatch_async(kcBgQueue, ^{
        NSData *data = [NSData dataWithContentsOfURL:
                            [KCMovieFetcher OMDBAPISearchURLWithQuery:query]];
                
            NSDictionary *dict = [self parseOMDBResponseData:data];
    
            
            [_delegate movieFetcherDidRecieveOMDBAPISearchResults:dict];
    });
}

//
// Parses the response data from the previous search.
// Returns a NSDcitionary with all the information, or
// an error inside it.
//


- (NSDictionary *)parseOMDBResponseData:(NSData *)data
{
    // 1. No data retrived. Return error in dictionary.
    if (data == nil) {
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"No data retrived.", NSLocalizedDescriptionKey, nil];
        NSError *error;
        error = [NSError errorWithDomain:@"movieFetcher.omdb" code:402 userInfo:info];
        return [NSDictionary dictionaryWithObject:error forKey:@"error"];}
    
    // 2. Data recieved. Create JSON Object.
    NSError *e;
    NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&e];
    return JSON;
}


#pragma mark Data Loading

/*
 Recieves JSON object for movie from OMDBAPI on a background thread.
 Once the call completes, sends method to delegate with whatever 
 the query returned.
*/

- (void)fetchAPIDataForMovieTitle:(NSString *)title year:(NSString *)year imdbID:(NSString *)imdbid
{
    _movieTags = [NSDictionary dictionaryWithObjectsAndKeys: title, @"title", year, @"year", nil];
    
    dispatch_async(kcBgQueue, ^{
        NSData *imdbData = [NSData dataWithContentsOfURL:
                            [KCMovieFetcher OMDBAPIMovieURLForTitle:title year:year imdbid:imdbid]];
        
        [self performSelectorOnMainThread:@selector(didLoadMovieData:) withObject:imdbData waitUntilDone:NO];
    });
}

- (void)didLoadMovieData:(NSData *)data
{    
    // 1. No data retrived. Return error message.
    if (data == nil) {
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"No data retrived.", NSLocalizedDescriptionKey, nil];
        NSError *error;
        error = [NSError errorWithDomain:@"movieFetcher.details" code:402 userInfo:info];
        [_delegate movieFetcherDidFailToLoadAPIDataForMovieTags:_movieTags withError:error];
        return;}
    
    // 2. Data recieved. Create JSON Object.
    NSError *e;
    NSDictionary *imdbJSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&e];
    
    // 3. Good response. Send dictionary with info.
    if ([[imdbJSON objectForKey:@"Response"] isEqualToString:@"True"]) {
        [_delegate movieFetcherDidLoadDataForMovieTags:_movieTags inDictionary:imdbJSON];}
    
    // π: Negative Response. Return error.
    else {
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Bad response. Nothing found!", NSLocalizedDescriptionKey, nil];
        NSError *error;
        error = [NSError errorWithDomain:@"movieFetcher.details" code:404 userInfo:info];
        [_delegate movieFetcherDidFailToLoadAPIDataForMovieTags:_movieTags withError:error];
        return;
    }
}

#pragma mark iTunes Data
//
// Loads poster image from iTunes
//

- (void)fetchiTunesDataForMovieTitle:(NSString *)title year:(NSString *)year
{
    _movieTags = [NSDictionary dictionaryWithObjectsAndKeys:
                  title, @"title", year, @"year", nil];
    dispatch_async(kcBgQueue, ^{
        NSURL *itunesYearQuery = [KCMovieFetcher iTunesYearQueryFromYear:year];
        NSLog(@"itunes: %@ ", itunesYearQuery);
        NSData *data = [NSData dataWithContentsOfURL:itunesYearQuery];
        [self performSelectorOnMainThread:@selector(didLoadYearDataFromiTunes:) withObject:data waitUntilDone:NO];
    });
}

- (void)didLoadYearDataFromiTunes:(NSData *)data
{  // 0. Check if data was recieved
    if (data == nil) {
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"No data retrived.", NSLocalizedDescriptionKey, nil];
        NSError *error;
        error = [NSError errorWithDomain:@"movieFetcher.image" code:402 userInfo:info];
        [_delegate movieFetcherDidFailToLoadAPIDataForMovieTags:_movieTags withError:error];
        return;}
    
    // 1. Load iTunes year's data into NSDictionary and get results
    NSError *e;
    NSDictionary *iTunesJSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&e];

    NSArray *results = [iTunesJSON objectForKey:@"results"];
    NSLog(@"Results");
    // 2. Check if data is good, if not return error.
    if ([results count] == 0) {
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Bad response. Nothing found!", NSLocalizedDescriptionKey, nil];
        NSError *error;
        error = [NSError errorWithDomain:@"movieFetcher.image" code:404 userInfo:info];
        [_delegate movieFetcherDidFailToLoadiTunesDataForMovieTags:_movieTags withError:error];
        return;}
    
    // 3. Look through the year's movies for the we're looking for
    NSString *title = [_movieTags objectForKey:@"title"];
    for (NSDictionary *item in results) {
        if ([[item objectForKey:@"trackName"] rangeOfString:title].location != NSNotFound)
        { // Found it. yay! Done.
            [_delegate movieFetcherDidLoadiTunesDataForMovieTags:_movieTags inDictionary:item];
            return;
        }
    }
    
    // 4. Found nothing. Search with title this time.
    [self fetchiTunesDataForMovieTitle:title];
}

- (void)fetchiTunesDataForMovieTitle:(NSString *)title
{
    NSLog(@"One down. Loading with names");
    _movieTags = [NSDictionary dictionaryWithObjectsAndKeys:
                  title, @"title", nil];

    dispatch_async(kcBgQueue, ^{
        NSURL *itunesMovieQuery = [KCMovieFetcher iTunesMovieQueryFromTitle:title];
        NSData *data = [NSData dataWithContentsOfURL:itunesMovieQuery];
        [self performSelectorOnMainThread:@selector(didLoadTitleDataFromiTunes:) withObject:data waitUntilDone:NO];
    });
}

- (void)didLoadTitleDataFromiTunes:(NSData *)data
{   // 0. Check if we got any data. Sende error if not.
    if (data == nil) {
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"No data retrived.", NSLocalizedDescriptionKey, nil];
        NSError *error;
        error = [NSError errorWithDomain:@"movieFetcher.image" code:402 userInfo:info];
        [_delegate movieFetcherDidFailToLoadAPIDataForMovieTags:_movieTags withError:error];
        return;}
    
    // 1. Load iTunes year's data into NSDictionary and get results
    NSError *e;
    NSDictionary *iTunesJSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&e];
    
    NSArray *results = [iTunesJSON objectForKey:@"results"];
    
    // 2. Send error if no results for the query were recieved
    
    if ([results count] == 0) {
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Bad response. Nothing found!", NSLocalizedDescriptionKey, nil];
        NSError *error;
        error = [NSError errorWithDomain:@"movieFetcher.image" code:404 userInfo:info];
        [_delegate movieFetcherDidFailToLoadiTunesDataForMovieTags:_movieTags withError:error];
        NSLog(@"Failed with title.");
        return;}
    
    else {
        [_delegate movieFetcherDidLoadiTunesDataForMovieTags:_movieTags inDictionary:[iTunesJSON valueForKey:@"results"][0]];
    }

}

#pragma mark -
#pragma mark URL Builders

// Returns escaped URL for a search in OMDB with a given query.
//
+ (NSURL *)OMDBAPISearchURLWithQuery:(NSString *)query
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://www.omdbapi.com/?s=%@&tomatoes=true", [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];}
///---------------


+ (NSURL *)OMDBAPIMovieURLForTitle:(NSString *)title year:(NSString *)year imdbid:(NSString *)imdbid
{
    
    NSString *imdbMovieQuery = [NSString string];
    
    // If we have an imdbID, it is priority.
    if (imdbid != nil && ![imdbid isEqualToString:@""]) {
        
#warning Should test this
        if ([imdbid rangeOfString:@"tt\\d{7}" options:NSRegularExpressionSearch].location != NSNotFound)
        {
            NSLog(@"Requesting through IMDBID: %@", imdbid);
            imdbMovieQuery = [NSString stringWithFormat:
                              @"http://www.omdbapi.com/?i=%@&r=JSON&plot=short&tomatoes=true",
                              imdbid];
            return [NSURL URLWithString:imdbMovieQuery];
        }

    }

    
    // 1. If the year is given, build query using it.
    if (year != nil && ![year isEqualToString:@""]) {
        //TODO: CHECK FOR 4 characters too
        imdbMovieQuery = [NSString stringWithFormat:
                          @"http://www.omdbapi.com/?t=%@&y=%@&r=JSON&plot=short&tomatoes=true",
                          [title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                          [year stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        // 2. If the year is not given, build query only with title
    } else {
        imdbMovieQuery = [NSString stringWithFormat:
                          @"http://www.omdbapi.com/?t=%@&r=JSON&plot=short&tomatoes=true",
                          [title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    
       
    NSLog(@"URL Ready: %@", imdbMovieQuery);
    return [NSURL URLWithString:imdbMovieQuery];
}

+ (NSURL *)iTunesYearQueryFromYear:(NSString *)year
{
    return [NSURL URLWithString:[NSString stringWithFormat:
            @"http://itunes.apple.com/search?media=movie&attribute=releaseYearTerm&term=%@",
            [year stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

+ (NSURL *)iTunesMovieQueryFromTitle:(NSString *)title
{
    return [NSURL URLWithString:[NSString stringWithFormat:
            @"http://itunes.apple.com/search?term=%@&media=movie",
            [title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}
@end
