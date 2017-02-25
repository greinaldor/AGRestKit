//
//  AGRestRequest+AGRestRequest_Format.m
//  Pods
//
//  Created by Adrien Greiner on 02/11/2015.
//
//

#import "AGRestRequest+Format.h"

#import"AGRestManager.h"
#import "AGRestServerProtocol.h"

@implementation AGRestRequest (Format)

- (NSString *)httpMethodString {
    NSString *httpMethod = nil;
    switch (self.httpMethod) {
        case AGRestRequestMethodHttpPOST:   httpMethod = @"POST"; break;
        case AGRestRequestMethodHttpGET:    httpMethod = @"GET"; break;
        case AGRestRequestMethodHttpDELETE: httpMethod = @"DELETE"; break;
        case AGRestRequestMethodHttpHEAD:   httpMethod = @"HEAD"; break;
        case AGRestRequestMethodHttpPUT:    httpMethod = @"PUT"; break;
        case AGRestREquestMethodHttpPATCH:  httpMethod = @"PATCH"; break;
        default: break;
    }
    return httpMethod;
}

- (NSString *)cURLRequestString {
    NSMutableString *curlString = [NSMutableString stringWithFormat:@"curl -k -X \"%@\" \"%@\"", self.httpMethodString, self.requestURL];
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    [headers setObject:@"application/json" forKey:@"Content-Type"];
    [headers addEntriesFromDictionary:self.headers];
    
    for (NSString *key in headers) {
        
        NSString *headerKey = key;
        NSString *headerValue = headers[key];
        
        [curlString appendFormat:@" -H \"%@: %@\"", headerKey, headerValue];
    }
    
    NSMutableDictionary *bodyDict = [NSMutableDictionary dictionaryWithCapacity:self.body.count];
    for (NSString *key in self.body.allKeys)
    {
        NSString *value = self.body[key];
        
        NSString *newKey = [NSString stringWithFormat:@"\"%@\"", key];
        NSString *newValue = [NSString stringWithFormat:@"\"%@\"", value];
        
        bodyDict[newKey] = newValue;
    }
    
    NSError     *error = nil;
    NSData      *bodyData = [NSJSONSerialization dataWithJSONObject:bodyDict options:NSJSONWritingPrettyPrinted error:&error];
    NSString    *bodyJsonString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
    
    if (bodyJsonString.length && !error) {
        [curlString appendFormat:@" -d \"%@\"", bodyJsonString];
    }
    
    return curlString;
}

- (NSMutableURLRequest *)mutableUrlRequest {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.endPoint
                                                                                   relativeToURL:[NSURL URLWithString:self.baseUrl]]];
    [request setHTTPMethod:self.httpMethodString];
    if (self.headers && self.headers.count) {
        [request setAllHTTPHeaderFields:self.headers];
    }
    if (self.body) {
        [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:self.body options:NSJSONWritingPrettyPrinted error:nil]];
    }
    return request;
}

@end
