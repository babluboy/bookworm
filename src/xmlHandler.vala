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

public class BookwormApp.XMLData {
        public bool shouldExtractionStart = false;
        public bool useLocalTagName = true;
        public bool isContainerTagMatched = false;
        public string currentTagName;
        public StringBuilder charBuffer = new StringBuilder("");

        public string containerTagName;
        public string inputTagName;
        public string inputAttributeName;
        public ArrayList<string> extractedTagValues = new ArrayList<string>();
        public ArrayList<string> extractedTagAttributes = new ArrayList<string>();
}

public class BookwormApp.XmlParser {
    private static XMLData thisXMLData;

    public XmlParser(){
        thisXMLData = null;
    }    
    
    /*
    public static int main(string[] args) {
        Environment.set_variable ("G_MESSAGES_DEBUG", "all", true);
        Log.set_handler ("", GLib.LogLevelFlags.LEVEL_DEBUG, GLib.Log.default_handler);

        string pathToXMLFile = "/home/sid/Documents/Projects/misc/xmlFiles/toc.ncx";
        //string pathToXMLFile = "/home/sid/Documents/Projects/misc/xmlFiles/test.opf";
        //string pathToXMLFile = "/home/sid/Documents/Projects/misc/xmlFiles/container.xml";
        //string pathToXMLFile = "/home/sid/.config/bookworm/books/The Da Vinci Code.epub/OEBPS/Content.opf";
        
        ArrayList<XMLData> inputDataList = new ArrayList<XMLData>();
        inputDataList.add(new XMLData() {
                            containerTagName = "rootfiles",
                            inputTagName = "rootfile",
                            inputAttributeName="full-path"}
                        );
        inputDataList.add(new XMLData() {
                                        containerTagName = "manifest",
                                        inputTagName = "item",
                                        inputAttributeName="id"}
                                        );
        inputDataList.add(new XMLData() {
                                        containerTagName = "manifest",
                                        inputTagName = "item",
                                        inputAttributeName="href"}
                                        );
        inputDataList.add(new XMLData() {
                                        containerTagName = "spine",
                                        inputTagName = "itemref",
                                        inputAttributeName="idref"}
                                        );
        inputDataList.add(new XMLData() {
                                    containerTagName = "",
                                    inputTagName = "spine",
                                    inputAttributeName="toc"}
                                    );
        inputDataList.add(new XMLData() {
                                    containerTagName = "",
                                    inputTagName = "subject",
                                    inputAttributeName=""}
                                    ); 
        inputDataList.add(new XMLData() {
                            containerTagName = "navLabel",
                            inputTagName = "text",
                            inputAttributeName=""}
                        );
        inputDataList.add(new XMLData() {
                            containerTagName = "",
                            inputTagName = "content",
                            inputAttributeName="src"}
                        );
    
        XmlParser thisParser = new XmlParser();
        ArrayList<XMLData> extractedDataList = new ArrayList<XMLData>();
        extractedDataList = thisParser.extractDataFromXML(pathToXMLFile, inputDataList);

        //Display the extracted data
        foreach(XMLData aExtractedData in extractedDataList){
            debug("************************************Showing Extracted Data for "+
                                    aExtractedData.containerTagName+"/"+aExtractedData.inputTagName+"/"+aExtractedData.inputAttributeName+
                         "**********************");
            debug("Items in List:"+aExtractedData.extractedTagValues.size.to_string());
            foreach(string aTagValue in aExtractedData.extractedTagValues){
                debug("Tag Value:"+aTagValue);
            }
            debug("Items in List:"+aExtractedData.extractedTagAttributes.size.to_string());
            foreach(string aAttributeValue in aExtractedData.extractedTagAttributes){
                debug("Attribute Value:"+aAttributeValue);
            }
        }

        return 0;
    }
    */

    public ArrayList<XMLData> extractDataFromXML (string path, owned ArrayList<XMLData> inputDataList){
        int count = 0;
        foreach(XMLData aXMLData in inputDataList){
            debug("Reading XML to extract data for input set #"+count.to_string()+":"+
                          aXMLData.containerTagName+"/"+aXMLData.inputTagName+"/"+aXMLData.inputAttributeName);
            thisXMLData = aXMLData;        
            parseXML(path);
            inputDataList[count] = thisXMLData;
            count++;
        }
        return inputDataList;
    }

    public void parseXML(string path) {
        Parser.init();
        var handler = SAXHandler();
        void* user_data = null;

        handler.startElement = start_element;
        handler.characters = get_text;
        handler.endElement = end_element;

        handler.user_parse_file(user_data, path);
        Parser.cleanup();
    }

    public void start_element(string name, string[] attributeList) {
        //debug(">>>>>Start Tag:"+name);
        thisXMLData.currentTagName = process_tagname(name);
        //If Start element matches container tag - set container flag to true 
        if(thisXMLData.currentTagName == thisXMLData.containerTagName) {
            thisXMLData.isContainerTagMatched = true;
        }
        
        //Check if the tag name matches the input tag name
        if(thisXMLData.currentTagName == thisXMLData.inputTagName){
            //Check if a container tag is required and if it has been matched - set extraction flag to true
            if(thisXMLData.containerTagName.length != 0 && thisXMLData.isContainerTagMatched){
                thisXMLData.shouldExtractionStart = true;
                thisXMLData.charBuffer.assign("");
            }else{
                //Check if no container tag is required and since the tag name has been matched - set extraction flag to true
                if(thisXMLData.containerTagName.strip().length == 0){
                    thisXMLData.shouldExtractionStart = true;
                    thisXMLData.charBuffer.assign("");
                }
            }
        }

        //If Extraction criteria is met and attribute extraction is required, extract required attribute
        if(thisXMLData.shouldExtractionStart && thisXMLData.inputAttributeName.length > 0) { //check whether attributes are expected
            int count = 0;
            foreach (string attribute in attributeList){
                if(attributeList.length >= count+1){
                    if(thisXMLData.inputAttributeName == attributeList[count]) {            
                        //extract the odd attribute data as the even attribute is the name of the attribute
                        thisXMLData.extractedTagAttributes.add(attributeList[count+1]);
                        break;
                    }
                    count = count + 2;
                }
            }
        }
    }

    public void end_element(string name) {
        //debug("<<<<<End Tag:"+name);
        string processed_name = process_tagname(name);
        //If End element matches container tag - set container flag to false and extraction flag to false
        if(processed_name == thisXMLData.containerTagName) {
            thisXMLData.isContainerTagMatched = false;
            thisXMLData.shouldExtractionStart = false;
        }

        //Check if tag name has been matched - set extraction flag to false
        if(processed_name == thisXMLData.inputTagName){
            //Add the collected tag value data into the extracted list
            if( thisXMLData.shouldExtractionStart && 
                thisXMLData.currentTagName == thisXMLData.inputTagName ) //this check ensures unrelated tags within a required tag are not picked up
            {
                thisXMLData.extractedTagValues.add(thisXMLData.charBuffer.str);
            }
            thisXMLData.shouldExtractionStart = false;
            thisXMLData.currentTagName = "";
        }
    }
 
    public void get_text (string chars, int len){
        //debug("........Tag Data [len="+len.to_string()+"] :"+chars.slice(0, len));
        //Extract tag value if extraction criteria is met       
        if( thisXMLData.shouldExtractionStart && 
            thisXMLData.currentTagName == thisXMLData.inputTagName ) //this check ensures unrelated tags within a required tag are not picked up
        {
            thisXMLData.charBuffer.append(chars.slice(0, len));
        }
    }

    public string process_tagname (string tagname){
        string local_tagname = tagname.strip();
        if(thisXMLData.useLocalTagName){
            if(local_tagname.index_of(":") != -1){
                local_tagname = local_tagname.slice(local_tagname.index_of(":")+1, local_tagname.length);
            }
        }
        return local_tagname;
    }
}

//valac --pkg libxml-2.0 --pkg gee-0.8 saxParser.vala
