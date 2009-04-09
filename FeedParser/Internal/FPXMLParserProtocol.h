/*
 *  FPXMLParserProtocol.h
 *  FeedParser
 *
 *  Created by Kevin Ballard on 4/9/09.
 *  Copyright 2009 Kevin Ballard. All rights reserved.
 *
 */

/*!
    @protocol
    @abstract    FPXMLParserProtocol declares a protocol for a tree of XML parser delegates
    @discussion  Every class that can be a delegate of the NSXMLParser must conform to this protocol.
				 This ensures that each class can pass parser delegation to its parent appropriately.
*/

@protocol FPXMLParserProtocol <NSObject>
@required
/*!
    @method     
    @abstract   Take over the delegate role for the NSXMLParser
	@param parser The NSXMLParser that is currently parsing the document.
    @discussion The implementation of this method must call [parser setDelegate:self]
				after recording the previous delegate of the parser. The previous
				delegate should be assumed to conform to FPXMLParserProtocol.
*/
- (void)acceptParsing:(NSXMLParser *)parser;
/*!
    @method     
    @abstract   Abort parsing
	@param parser The NSXMLParser that is currently parsing the document.
	@param description A description of the error that occurred. If no description is known, it will be nil.
    @discussion When an error occurs, whether it's an XML error or a validation error,
				the parser must call this method. It should do any cleanup necessary, and
				it must call this same method on its parent parser. If the parent parser
				does not exist, then it must call [parser abortParsing].
				Normally FPXMLParser is the root parser and will abort the parser.
				Be aware that the call to super may cause self to be deallocated.
*/
- (void)abortParsing:(NSXMLParser *)parser withString:(NSString *)description;
@end
