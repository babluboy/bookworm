/* Copyright 2018 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and handles all xml related parsing
*
* Bookworm is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* Bookworm is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Bookworm. If not, see http://www.gnu.org/licenses/.
*/

using Xml;
using Gee;
public class BookwormApp.XMLHandler {
    public Xml.TextReader reader;

    public XMLHandler(string uri) {
        reader = new Xml.TextReader.filename(uri);
        if (reader != null) {
                debug("Sucessfully opened XML file:"+uri);
        } else {
                warning("Unable to open:"+uri);
        }           
        Xml.Parser.cleanup();
    }
       
    public static ArrayList<string> extractElementAndAttribute( string uri, 
                                                                                                           string containerName, 
                                                                                                           string elementName, 
                                                                                                           string attributeTagName, 
                                                                                                           string attributeTagID) {
        int readStatus;
        ArrayList<string> extractedDataList = new ArrayList<string>();
        Xml.ReaderType current_type;
        XMLHandler aXMLHandler = new XMLHandler(uri);
        readStatus = aXMLHandler.reader.read();
        bool isNavPointContainer = false;
        StringBuilder extractedElementValue = new StringBuilder("");
        StringBuilder extractedAttributeValue = new StringBuilder("");
        //loop through the complete xml
        while (readStatus == 1) {
            current_type = (Xml.ReaderType) aXMLHandler.reader.node_type ();
            //check is the start element is "navPoint"
            if (current_type == Xml.ReaderType.ELEMENT || aXMLHandler.reader.local_name () == containerName) {
                isNavPointContainer = true;
            }
            if(isNavPointContainer){
                 //check if the start element is "content"
                if ((current_type == Xml.ReaderType.ELEMENT || 
                    aXMLHandler.reader.local_name () == attributeTagName) &&
                    aXMLHandler.reader.get_attribute(attributeTagID) != null &&
                    aXMLHandler.reader.get_attribute(attributeTagID).strip().length > 0) {
                    extractedElementValue.assign(aXMLHandler.reader.get_attribute(attributeTagID).strip());
                }
                //check if the start element is "text"
                if ((current_type == Xml.ReaderType.ELEMENT || 
                    aXMLHandler.reader.local_name () == "#"+elementName) &&
                    aXMLHandler.reader.const_value() != null &&
                    aXMLHandler.reader.const_value().strip().length > 0) {
                    extractedAttributeValue.assign(aXMLHandler.reader.const_value().strip());
                }
                if(extractedElementValue.str.length > 0 && extractedAttributeValue.str.length > 0){
                    //collect the data only if both are available
                    extractedDataList.add (extractedAttributeValue.str+"#~#~#~#"+extractedElementValue.str);                    
                    extractedAttributeValue.assign("");
                    extractedElementValue.assign("");
                }
            }
            //check if the end element is "navPoint"
            if (current_type == Xml.ReaderType.END_ELEMENT || aXMLHandler.reader.local_name () == containerName) {
                isNavPointContainer = false;
            }
            //continue iteration
            readStatus = aXMLHandler.reader.read();
        }
        aXMLHandler.reader = null; // TODO fixme c-function is xmlFreeTextReader(reader);
        if (readStatus != 0) {
            warning("Failed to parse xml file");
        }
        return extractedDataList;
    }
}
