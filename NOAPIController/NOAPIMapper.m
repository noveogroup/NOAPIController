//
//  NOAPIMapper.m
//  NOAPIControllerExample
//
//  Created by Alexander Gorbunov on 13/04/15.
//  Copyright (c) 2015 Noveo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.


#import "NOAPIMapper.h"
@import ObjectiveC;


@interface NOAPIMapper ()
@property (nonatomic) id transformer;
@property (nonatomic) NSDictionary *fieldsMap;
@end


@implementation NOAPIMapper

#pragma mark - Object lifecycle

- (instancetype)initWithFieldsMap:(NSDictionary *)fieldsMap transformer:(id)transformer
{
    self = [self init];
    if (self) {
        _fieldsMap = fieldsMap;
        _transformer = transformer;
    }
    return self;
}

#pragma mark - Public methods

- (id)objectOfType:(Class)objectType fromDictionary:(NSDictionary *)rawObject
{
    id objectTransformer = self.fieldsMap[NSStringFromClass(objectType)];
    id (*transform)(id, SEL, id) = (id (*)(id, SEL, id))objc_msgSend;

    // Use external parser method
    if ([objectTransformer isKindOfClass:[NSString class]]) {
        SEL transformerSelector = NSSelectorFromString(objectTransformer);
        return transform(self.transformer, transformerSelector, rawObject);
    }
    // Parse each field
    else {
        if ([rawObject isKindOfClass:objectType]) {
            return rawObject;
        }

        if (![rawObject isKindOfClass:[NSDictionary class]]) {
            return nil;
        }

        if (!objectTransformer) {
            return nil;
        }

        id object = [[objectType alloc] init];
        NSDictionary *fields = objectTransformer;
        
        for (NSString *fieldKey in fields.allKeys) {
            NSDictionary *fieldDescription = fields[fieldKey];

            NSString *objectKey = fieldDescription[@"key"];
            if (!objectKey) {
                objectKey = fieldKey;
            }
            
            NSString *arrayItemClassName = fields[fieldKey][@"arrayOf"];
            NSString *dictionaryItemClassName = fields[fieldKey][@"dictionaryOf"];
            NSString *typeTransformer = fieldDescription[@"transformer"];
            NSString *classOfObject = fieldDescription[@"kindOf"];
            NSString *typeOfField = fieldDescription[@"type"];

            // Parse array of sub-objects.
            if (arrayItemClassName) {
                NSArray *innerArray = [rawObject valueForKeyPath:fieldKey];
                if ([innerArray isKindOfClass:[NSArray class]]) {
                    NSMutableArray *arrayOfItems = [NSMutableArray array];
                    for (NSDictionary *arrayItemDescription in innerArray) {
                        id arrayItem = nil;
                        // Just copy array values (array of NSStrings for example).
                        if ([arrayItemDescription isKindOfClass:NSClassFromString(arrayItemClassName)]) {
                            arrayItem = arrayItemDescription;
                        }
                        // Parse array element.
                        else {
                            arrayItem = [self objectOfType:NSClassFromString(arrayItemClassName)
                                fromDictionary:arrayItemDescription];
                        }
                        if (arrayItem) {
                            [arrayOfItems addObject:arrayItem];
                        }
                        else {
                            NSLog(@"Warning: API response for <%@> contains unexpected value: <%@>%@"
                                "for key \"%@\"while in array, while <%@> is expected.", objectType,
                                [arrayItemDescription class], arrayItemDescription, fieldKey,
                                arrayItemClassName);
                        }
                    }
                    [object setValue:arrayOfItems forKey:objectKey];
                }
                else if (innerArray == nil || [innerArray isKindOfClass:[NSNull class]]) {
                    // No value is ok.
                }
                else {
                    NSLog(@"Warning: API response for <%@> contains unexpected value: <%@>%@"
                        "for key \"%@\"while an array is expected.", objectType,
                        [innerArray class], innerArray, fieldKey);
                }
            }
            
            // Parse values of dictionary as array.
            else if (dictionaryItemClassName) {
                if ([rawObject[fieldKey] isKindOfClass:[NSDictionary class]]) {
                    NSMutableDictionary *dictOfItems = [NSMutableDictionary dictionary];
                    [rawObject[fieldKey] enumerateKeysAndObjectsUsingBlock:
                        ^(id key, NSDictionary *dictItemDescription, BOOL *stop) {
                            id dictItem = [self objectOfType:NSClassFromString(dictionaryItemClassName)
                                fromDictionary:dictItemDescription];
                            dictOfItems[key] = dictItem;
                        }];
                    [object setValue:dictOfItems forKey:objectKey];
                }
            }
            
            // Parse object that should be transformed.
            else if (typeTransformer) {
                SEL transformerSelector = NSSelectorFromString(typeTransformer);
                id transformedData = transform(self.transformer, transformerSelector,
                    [rawObject valueForKeyPath:fieldKey]);
                [object setValue:transformedData forKey:objectKey];
            }
            
            // Parse object according to its class.
            else if (classOfObject) {
                if (typeOfField) {
                    id innerObject = [rawObject valueForKeyPath:fieldKey];
                    if (![innerObject isKindOfClass:NSClassFromString(typeOfField)]) {
                        if (![innerObject isKindOfClass:[NSNull class]]) {
                            NSLog(@"Warning: API response for <%@> contains unexpected value: <%@>%@"
                                "for key \"%@\"while an instance of <%@> is expected.", objectType,
                                [innerObject class], innerObject, fieldKey, typeOfField);
                        }
                        continue;
                    }
                }
                
                id innerObject = [self objectOfType:NSClassFromString(classOfObject)
                    fromDictionary:[rawObject valueForKeyPath:fieldKey]];
                if (object) {
                    [object setValue:innerObject forKeyPath:objectKey];
                }
            }
            
            // Check type of the value, don't copy invalid values.
            else if (typeOfField) {
                id innerObject = [rawObject valueForKeyPath:fieldKey];
                if ([innerObject isKindOfClass:NSClassFromString(typeOfField)]) {
                    [object setValue:[rawObject valueForKeyPath:fieldKey] forKey:objectKey];
                }
                else if (innerObject == nil || [innerObject isKindOfClass:[NSNull class]]) {
                    // No value is ok.
                }
                else {
                    NSLog(@"Warning: API response for <%@> contains unexpected value: <%@>%@"
                        "for key \"%@\"while an instance of <%@> is expected.", objectType,
                        [innerObject class], innerObject, fieldKey, typeOfField);
                }
            }
            
            // Plain value copy.
            else {
                id innerObject = [rawObject valueForKeyPath:fieldKey];
                if (innerObject) {
                    [object setValue:[rawObject valueForKeyPath:fieldKey] forKey:objectKey];
                }
            }
        }
        return object;
    }
}

@end
