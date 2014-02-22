#KCMovieFetcher 0.5

A script to fetch movie information from the [OMDB API][1] (with a bit of iTunes support too). 

##Usage.

1. `#import "KCMovieFetcher.h"`

2. Make a KCMovieFetcher Delegate.

3. Create a new fetcher and call stuff on it. 

``` 
KCMovieFetcher *fetcher = [[KCMovieFetcher init] alloc];

[fetcher searchOMDBAPIWithQuery]; // Will asynchronously search and call
```


[1]:http://www.omdbapi.com

##Methods.

```
- (void)searchOMDBAPIWithQuery:(NSString *)query;
- (void)searchiTunesWithQuery:(NSString *)query;

- (void)fetchAPIDataForMovieTitle:(NSString *)title year:(NSString *)year imdbID:(NSString *)imdbid;;
- (void)fetchiTunesDataForMovieTitle:(NSString *)title year:(NSString *)year;

+ (NSURL *)OMDBAPISearchURLWithQuery:(NSString *)query;
+ (NSURL *)OMDBAPIMovieURLForTitle:(NSString *)title year:(NSString *)year imdbid:(NSString *)imdbid;
```

##Delegate Methods. 

They are all optional.

```
- (void)movieFetcherDidRecieveOMDBAPISearchResults:(NSDictionary *)results;
- (void)movieFetcherDidRecieveiTunesSearchResults:(NSDictionary *)results;

- (void)movieFetcherDidRecievePosterImageData:(NSData *)data forMovieTags:(NSDictionary *)movie;

- (void)movieFetcherDidLoadDataForMovieTags:(NSDictionary *)movie inDictionary:(NSDictionary *)info;
- (void)movieFetcherDidLoadiTunesDataForMovieTags:(NSDictionary *)movie inDictionary:(NSDictionary *)info;

- (void)movieFetcherDidFailToLoadAPIDataForMovieTags:(NSDictionary *)movieTags withError:(NSError *)error;
- (void)movieFetcherDidFailToLoadiTunesDataForMovieTags:(NSDictionary *)movieTags withError:(NSError *)error;
```

##Notes.

There's still stuff to do. Feel free to contribute if you're feeling adventurous!

1. Cleaning up the code a bit
2. Adding `block` support
3. More iTunes support.
4. Bugs, bugs, bugs.