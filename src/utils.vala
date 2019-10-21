/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and contains some utility functions
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

using Gee;
namespace BookwormApp.Utils {
    public string last_file_chooser_path = null;
    public static StringBuilder spawn_async_with_pipes_output;
    public string bookwormStateData;

    public bool process_line (IOChannel channel, IOCondition condition, string stream_name) {
        if (spawn_async_with_pipes_output == null) {
            spawn_async_with_pipes_output = new StringBuilder ("");
        }
        if (condition == IOCondition.HUP) {
            return false;
        }
        try {
            string line;
            channel.read_line (out line, null, null);
            spawn_async_with_pipes_output.append (line);
        } catch (IOChannelError e) {
            spawn_async_with_pipes_output.append (e.message);
            return false;
        } catch (ConvertError e) {
            spawn_async_with_pipes_output.append (e.message);
            warning ("Failure in reading command output:" + e.message);
            return false;
        }
        return true;
    }

    public int execute_async_multiarg_command_pipes (string[] spawn_args) {
        if (spawn_async_with_pipes_output == null) {
            spawn_async_with_pipes_output = new StringBuilder ("");
        }
        debug ("Starting to execute async command: " + string.joinv (" ", spawn_args));
        spawn_async_with_pipes_output.erase (0, -1); //clear the output buffer
        MainLoop loop = new MainLoop ();
        try {
            string[] spawn_env = Environ.get ();
            Pid child_pid;
            int standard_input;
            int standard_output;
            int standard_error;
            Process.spawn_async_with_pipes ("/",
                spawn_args, spawn_env, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                null, out child_pid, out standard_input, out standard_output, out standard_error);
            // capture stdout:
            IOChannel output = new IOChannel.unix_new (standard_output);
            output.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
                return process_line (channel, condition, "stdout");
            });
            // capture stderr:
            IOChannel error = new IOChannel.unix_new (standard_error);
            error.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
                return process_line (channel, condition, "stderr");
            });
            ChildWatch.add (child_pid, (pid, status) => {
                // Triggered when the child indicated by child_pid exits
                Process.close_pid (pid);
                loop.quit ();
            });
            loop.run ();
        } catch (SpawnError e) {
            warning ("Failure in executing async command [" + string.joinv (" ", spawn_args) + "] : " + e.message);
            spawn_async_with_pipes_output.append (e.message);
        }
        debug ("Completed executing async command[" + string.joinv (" ", spawn_args) + "]...");
        return 0;
    }

    public string execute_sync_command (string cmd) {
        debug ("Starting to execute sync command [" + cmd + "]");
        string std_out;
        string std_err;
        int exitCodeForCommand = 0;
        try {
            Process.spawn_command_line_sync (cmd, out std_out, out std_err, out exitCodeForCommand);
            if (exitCodeForCommand != 0) {
                warning ("Execution of sync command [" + cmd + "]: exited with non zero error code[" + exitCodeForCommand.to_string () + "]. Error message:" + std_err);
                return "false";
            }
        } catch (Error e) {
            warning ("Error encountered in execution of sync command [" + cmd + "]: " + e.message);
            return "false";
        }
        debug ("Completed execution of sync command [" + cmd + "] with output:" + std_out);
        return std_out;
    }

    public string getFullPathFromFilename (string rootDirectoryToSearch, string fileName) {
        string grepOutput = "";
        try {
            string baseName = File.new_for_path (fileName).get_basename ();
            grepOutput = execute_sync_command ("find \"" + rootDirectoryToSearch + "\" -name \"" + baseName + "\"").strip ();
            //check if there are more than one result - return the first one
            if (grepOutput.contains ("\n")) {
                string[] listOfFilePaths = getListOfRepeatingSegments (grepOutput, "\n");
                grepOutput = listOfFilePaths[0];
            }
            ///TODO: handle the no file found error
            return grepOutput.strip ();
        } catch (Error e) {
            warning ("Error encountered in getting full path for filename [" + fileName + "] searching within directory[" + rootDirectoryToSearch + "]: " + e.message);
        }
        return grepOutput;
    }

    public string extractBetweenTwoStrings (string stringToBeSearched, string startString, string endString) throws Error {
            string extractedString = "";
            int positionOfStartStringInData = stringToBeSearched.index_of (startString, 0);
        if (positionOfStartStringInData > -1) {
            int positionOfEndOfStartString = positionOfStartStringInData + (startString.char_count (-1));
            int positionOfStartOfEndString = stringToBeSearched.index_of (endString, (positionOfEndOfStartString + 1));
            if (positionOfStartOfEndString > -1) {
                extractedString = stringToBeSearched.substring (positionOfEndOfStartString, (positionOfStartOfEndString - positionOfEndOfStartString)).strip ();
            }
        } else {
            extractedString = Constants.TEXT_FOR_NOT_AVAILABLE;
        }
        return extractedString;
    }

    public string[] multiExtractBetweenTwoStrings (string stringToBeSearched, string startString, string endString) {
        string[] results = new string[0];
        try {
            string taggedInput = stringToBeSearched.replace (startString, "#~#~#~#~#~#~#~#~#" + startString);
            string[] occurencesOfStartString = taggedInput.split ("#~#~#~#~#~#~#~#~#", -1);
            StringBuilder searchResult = new StringBuilder ();
            foreach (string splitString in occurencesOfStartString) {
                searchResult.assign (extractBetweenTwoStrings (splitString, startString, endString));
                if (searchResult.str != Constants.TEXT_FOR_NOT_AVAILABLE) {
                    results += searchResult.str;
                }
            }
        } catch (Error e) {
            warning ("Failure in utility multi extract between strings:" + e.message);
        }
        return results;
    }

    public string[] getListOfRepeatingSegments (string data, string repeatingIdentifier) throws Error {
        string[] segments = { "" };
        string currentSegment = "";
        int positionCurrentSegment = data.index_of (repeatingIdentifier);
        int positionOfNextSegment = 0;
        bool isSegmentsRemaning = true;
        if (positionCurrentSegment != -1) {
            while (isSegmentsRemaning) {
                positionOfNextSegment = data.index_of (repeatingIdentifier, positionCurrentSegment + 1);
                if (positionOfNextSegment != -1) {
                    currentSegment = data.substring (positionCurrentSegment, (positionOfNextSegment-positionCurrentSegment));
                    segments += currentSegment;
                    data.splice (positionCurrentSegment, positionOfNextSegment, "");
                    positionCurrentSegment = positionOfNextSegment;
                } else {
                    segments += data.substring (positionCurrentSegment);
                    isSegmentsRemaning = false;
                }
            }
        } else {
            segments = {Constants.TEXT_FOR_NOT_AVAILABLE};
        }
        return segments;
    }

    public Gee.ArrayList<Gee.ArrayList<string>> convertMultiLinesToTableArray (
        string dataForList,
        int noOfColumns,
        string columnToken
    ) throws Error {
        Gee.ArrayList<ArrayList<string>> rowsData = new Gee.ArrayList<Gee.ArrayList<string>> ();
        string[] individualLines = dataForList.strip ().split ("\n", -1); //split the multiline string lines into individual lines
        foreach (string line in individualLines) {
            string[] valuesInALine = line.strip ().split (columnToken, -1); //split the individual line into values based on a token
            Gee.ArrayList<string> columnsData = new Gee.ArrayList<string> ();
            for (int count = 0; count < noOfColumns; count++) {
                if (count <= valuesInALine.length && valuesInALine[count] != null) {
                    columnsData.add (valuesInALine[count].strip ());
                } else {
                    columnsData.add (" "); // set an empty space if no values are available for the column
                }
            }
            rowsData.add (columnsData);
        }
        return rowsData;
    }

    public string extractXMLTag (
        string xmlData,
        string startTag,
        string endTag
    ) throws Error {
        string extractedData = "";
        if (xmlData.contains (startTag) && xmlData.contains (endTag)) {
            extractedData = xmlData.slice (
                xmlData.index_of (startTag) + startTag.length,
                xmlData.index_of (endTag));
        }
        return extractedData;
    }

    public string extractXMLAttribute (
        string xmlData,
        string tagName,
        string attributeID,
        string attributeName
    ) throws Error {
        string extractedData = "";
        int startPos = -1;
        int endPos = -1;
        //find the first occurence of the required xml tag
        if (xmlData.contains ("<" + tagName) && xmlData.contains (attributeID + "=\"" + attributeName + "\"")) {
            //extract the data in the xml tag
            string tagData = xmlData.slice (
                xmlData.index_of ("<" + tagName),
                xmlData.index_of (">", xmlData.index_of ("<" + tagName) + 1));
            if (tagData.down ().contains ("value")) {
                startPos = xmlData.index_of ("value=\"", xmlData.index_of (attributeID + "=\"" + attributeName + "\"")) + 7;
                endPos = xmlData.index_of ("\"", startPos);
            } else {
                startPos = xmlData.index_of (">", xmlData.index_of ("<" + tagName)) + 1;
                endPos = xmlData.index_of ("</" + tagName + ">", xmlData.index_of ("<" + tagName));
            }
            if (startPos != -1 && endPos != -1 && endPos > startPos) {
                extractedData = xmlData.slice (startPos, endPos);
            }
        }
        return extractedData;
    }

    public Gee.HashMap<string, string> extractTagAttributes (
        string xmlData,
        string tagName,
        string attributeID,
        bool doesAttributeValueExists
    ) throws Error {
        Gee.HashMap<string, string> AttributeMap = new HashMap <string, string> ();
        int positionOfStartTag = 0;
        int positionOfEndTag = 0;
        int positionOfStartAttributeValue = 0;
        int positionOfEndAttributeValue = 0;
        int positionOfStartTagValue = 0;
        int positionOfEndTagValue = 0;
        string qualifiedTagName = "<" + tagName;
        string qualifiedAttributeID = attributeID + "=\"";
        StringBuilder attributeValue = new StringBuilder ("");
        StringBuilder tagValue = new StringBuilder ("");
        while (positionOfStartTag != -1) {
            positionOfStartTag = xmlData.index_of (qualifiedTagName, positionOfStartTag);
            if (doesAttributeValueExists) {
                positionOfEndTag = xmlData.index_of ("/>", positionOfStartTag);
            } else {
                positionOfEndTag = xmlData.index_of (">", positionOfStartTag);
            }
            if (positionOfEndTag > positionOfStartTag) {
                positionOfStartAttributeValue = xmlData.index_of (qualifiedAttributeID, positionOfStartTag);
                positionOfEndAttributeValue = xmlData.index_of ("\"", positionOfStartAttributeValue + qualifiedAttributeID.length);
                if (positionOfStartAttributeValue!=-1 && positionOfEndAttributeValue!=-1 && positionOfEndAttributeValue>positionOfStartAttributeValue) {
                    attributeValue.assign (xmlData.slice (positionOfStartAttributeValue + qualifiedAttributeID.length, positionOfEndAttributeValue));
                } else {
                    attributeValue.assign ("");
                }
                if (doesAttributeValueExists) {
                    positionOfStartTagValue = xmlData.index_of ("value=\"", positionOfStartTag);
                    positionOfEndTagValue = xmlData.index_of ("\"", positionOfStartTagValue + "value=\"".length);
                    if (positionOfStartTagValue!=-1 && positionOfEndTagValue!=-1 && positionOfEndTagValue>positionOfStartTagValue) {
                        tagValue.assign (xmlData.slice (positionOfStartTagValue + "value=\"".length, positionOfEndTagValue));
                    } else {
                        tagValue.assign ("");
                    }
                    if (attributeValue.str != "") {
                        AttributeMap.set (attributeValue.str, tagValue.str);
                    }
                } else {
                    positionOfStartTagValue = xmlData.index_of (">", positionOfStartTag);
                    positionOfEndTagValue = xmlData.index_of ("</", positionOfStartTagValue + 1);
                    if (positionOfStartTagValue!=-1 && positionOfEndTagValue!=-1 && positionOfEndTagValue>positionOfStartTagValue) {
                        tagValue.assign (xmlData.slice (positionOfStartTagValue + 1, positionOfEndTagValue));
                    } else {
                        tagValue.assign ("");
                    }
                    if (attributeValue.str != "") {
                        if (! (tagValue.str.contains ("<") || tagValue.str.contains (">"))) {
                            AttributeMap.set (attributeValue.str, tagValue.str);
                        }
                    }
                }
            }
            positionOfStartTag = positionOfEndTag;
        }
        return AttributeMap;
    }

    public string extractNestedXMLAttribute (
        string xmlData,
        string startTag,
        string endTag,
        int nestCount
    ) throws Error {
        string extractedData = "";
        StringBuilder xmlDataBuffer = new StringBuilder (xmlData);
        int positionOfStartTag = xmlData.index_of (startTag);
        if (positionOfStartTag != -1) {
            xmlDataBuffer.assign (xmlData.slice (positionOfStartTag, -1));
        }
        positionOfStartTag = xmlDataBuffer.str.index_of (startTag);
        int positionOfEngTag = 0;
        for (int count=0; count < nestCount; count++) {
            positionOfEngTag = xmlDataBuffer.str.index_of (endTag, positionOfStartTag + positionOfEngTag + 1);
        }
        if (positionOfStartTag != -1 && positionOfEngTag != -1 && positionOfEngTag>positionOfStartTag + startTag.length) {
            extractedData = xmlDataBuffer.str.slice (positionOfStartTag + startTag.length, positionOfEngTag);
        }
        return extractedData;
    }

    public static string fileOperations (
        string operation,
        string path,
        string filename,
        string contents
    ) {
        debug ("Started file operation[" + operation + "], for path=" + path + ", filename=" + filename);
        StringBuilder result = new StringBuilder ("false");
        string data = "";
        File fileDir = null;
        File file = null;
        try {
            if (path != null || path.length > 1) {
                fileDir = File.new_for_commandline_arg (path);
            }
            if (filename != null && filename.length > 1) {
                file = File.new_for_path (path + "/" + filename);
            } else {
                file = File.new_for_path (path);
            }
            ////TODO: Use switch (operation) istead of ifs
            if ("CREATEDIR" == operation) {
                //check if directory does not exists
                if (!fileDir.query_exists ()) {
                    //create the directory
                    fileDir.make_directory ();
                    result.assign ("true");
                    //close and release the file
                    FileUtils.close (new IOChannel.file (path, "r").unix_get_fd ());
                    debug ("Directory created:" + fileDir.get_path ());
                } else {
                    //do nothing
                    result.assign ("true");
                }
            }
            if ("WRITE" == operation) {
                //check if directory does not exists
                if (!fileDir.query_exists ()) {
                    //create the directory
                    fileDir.make_directory ();
                    //write the contents to file
                    FileUtils.set_contents (path + "/" + filename, contents);
                    result.assign ("true");
                } else {
                    //write or overwrite contents to file
                    FileUtils.set_data (path + "/" + filename, contents.data);
                    result.assign ("true");
                }
            }
            if ("WRITE_PROPS" == operation) {
                //check if directory does not exists
                if (!fileDir.query_exists ()) {
                    //create the directory
                    fileDir.make_directory ();
                    //write the contents to file
                    FileUtils.set_contents (path + "/" + filename, contents);
                }
                bool wasRead = FileUtils.get_contents (path + "/" + filename, out data);
                if (wasRead) {
                    string[] name_value = contents.split (Constants.IDENTIFIER_FOR_PROPERTY_VALUE, -1);
                    //get the contents of the file
                    result.assign (data);
                    //check if the property (name/value) exists
                    if (data.contains (name_value[0])) {
                        //extract the data before the property name
                        string dataBeforeProp = result.str.split (
                            Constants.IDENTIFIER_FOR_PROPERTY_START + contents.split (
                                Constants.IDENTIFIER_FOR_PROPERTY_VALUE, 2)[0], 2)[0];
                        //extract the data after the property name/value
                        string dataAfterProp = result.str.split (contents + Constants.IDENTIFIER_FOR_PROPERTY_END)[1];
                        //name/value exists - update the same
                        result.append (dataBeforeProp + contents + dataAfterProp);
                        //update the modified contents to file
                        FileUtils.set_contents (path + "/" + filename, result.str);
                    } else {
                        //name/value does not exists - write the same
                        result.append (Constants.IDENTIFIER_FOR_PROPERTY_START + contents + Constants.IDENTIFIER_FOR_PROPERTY_END);
                        FileUtils.set_contents (path + "/" + filename, result.str);
                    }
                } else {
                    result.assign ("false");
                }
            }
            if ("READ" == operation) {
                if (file.query_exists ()) {
                    bool wasRead = FileUtils.get_contents (path + "/" + filename, out data);
                    if (wasRead) {
                        result.assign (data);
                    } else {
                        result.assign ("false");
                    }
                } else {
                    result.assign ("false");
                }
            }
            if ("READ_FILE" == operation) {
                bool wasRead = FileUtils.get_contents (path, out data);
                if (wasRead) {
                    result.assign (data);
                } else {
                    result.assign ("false");
                }
            }
            if ("READ_PROPS" == operation) {
                if (bookwormStateData != null && bookwormStateData.length > 5) { //nutty state data exists - no need to read the nutty state file
                    data = bookwormStateData;
                } else { //nutty state data is not available - read the nutty state file
                    if (file.query_exists ()) {
                        bool wasRead = FileUtils.get_contents (path + "/" + filename, out data);
                        if (wasRead) {
                            //set the global variable for the nutty state data to avoid reading the contents again
                            bookwormStateData = data;
                        } else {
                            result.assign ("false");
                        }
                    } else {
                        result.assign ("false");
                    }
                }
                //get the part of the contents starting with the value of the props
                result.assign (data.split (
                    Constants.IDENTIFIER_FOR_PROPERTY_START + contents + Constants.IDENTIFIER_FOR_PROPERTY_VALUE, 2)[1]);
                //get the value of the prop
                result.assign (result.str.split (Constants.IDENTIFIER_FOR_PROPERTY_END, 2)[0]);
            }
            if ("DELETE" == operation) {
                FileUtils.remove (path + "/" + filename);
            }
            if ("EXISTS" == operation) {
                if (file.query_exists ()) {
                    result.assign ("true");
                }
            }
            if ("DIR_EXISTS" == operation) {
                if (fileDir.query_exists ()) {
                    result.assign ("true");
                }
            }
            if ("IS_EXECUTABLE" == operation) {
                if (FileUtils.test (path + "/" + filename, FileTest.IS_EXECUTABLE)) {
                    result.assign ("true");
                }
            }
            if ("MAKE_EXECUTABLE" == operation) {
                execute_sync_command ("chmod + x " + path + "/" + filename);
                result.assign ("true");
            }
            if ("SET_PERMISSIONS" == operation) {
                execute_sync_command ("chmod " + contents + " " + path + "/" + filename);
                result.assign ("true");
            }
        } catch (Error e) {
            warning ("Failure in File Operation [operation=" + operation + ", path=" + path + ", filename=" + filename + "]: " + e.message);
            result.assign ("false:" + e.message);
        }
        debug ("Completed file operation [" + operation + "]");
        return result.str;
    }

    public static Gee.ArrayList<string> createPagination (Gee.ArrayList<string> contentLocationList) {
        Gee.ArrayList<string> pageContentList = new Gee.ArrayList<string> ();
        StringBuilder aPageContent = new StringBuilder ("");
        int current_number_of_lines_per_page = 0;
        int current_position = 0;
        for (int i=0; i<contentLocationList.size; i++) {
            //extract contents from location
            string contents = BookwormApp.Utils.fileOperations ("READ_FILE", contentLocationList.get (i), "", "");
            while (current_position < contents.length) {
                while (current_number_of_lines_per_page < BookwormApp.Constants.MAX_NUMBER_OF_LINES_PER_PAGE) {
                    aPageContent.append (contents.slice (current_position, contents.index_of (" ",
                        current_position + BookwormApp.Constants.MAX_NUMBER_OF_CHARS_PER_LINE)))
                        .append (" ").append ("<br>");
                    //debug ("extracted line:" + aPageContent.str);
                    current_position = contents.index_of (" ",
                        current_position + BookwormApp.Constants.MAX_NUMBER_OF_CHARS_PER_LINE) + 1;
                    current_number_of_lines_per_page++;
                    debug ("current_position: " + current_position.to_string () +
                        ":::current_number_of_lines_per_page: " + current_number_of_lines_per_page.to_string ());
                    //break;
                }
                pageContentList.add (aPageContent.str);
                debug (aPageContent.str);
                aPageContent.erase (0, -1);
                //break;
            }
            break;
        }
        return pageContentList;
    }

    public static string createTableOfContents (Gee.ArrayList<string> bookContentList) {
        debug ("Started creating Table Of Contents....");
        StringBuilder tocHTML = new StringBuilder ();
        tocHTML.append ("<html>")
            .append ("<head></head>")
            .append ("<body> <font align=\"right\"><b>Book Contents</b>")
            .append ("<table>");
        for (int i=0; i<bookContentList.size; i++) {
            tocHTML.append ("<tr><td>").append (
                "<a href=\"" + BookwormApp.Constants.PREFIX_FOR_FILE_URL +
                bookContentList.get (i) + "\">Content Part " +
                (i + 1).to_string () + "</a></td><td>").append ("</td></tr>");
        }
        tocHTML.append ("</table></body></html>");
        debug ("Completed creating Table Of Contents");
        return tocHTML.str;
    }

    // Create a GtkFileChooserDialog to perform the action desired
    //The filterMap should be in the format: key=*.epub, value=ePUB, key=*.jpg, value=Images
    public Gtk.FileChooserDialog new_file_chooser_dialog (
        Gtk.FileChooserAction action,
        string title,
        Gtk.Window? parent,
        bool select_multiple,
        string filterType
    ) {
        Gtk.FileChooserDialog aFileChooserDialog = new Gtk.FileChooserDialog (title, parent, action);
        aFileChooserDialog.set_select_multiple (select_multiple);
        aFileChooserDialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        if (action == Gtk.FileChooserAction.OPEN) {
            aFileChooserDialog.add_button (_("Open"), Gtk.ResponseType.ACCEPT);
        } else {
            aFileChooserDialog.add_button (_("Save"), Gtk.ResponseType.ACCEPT);
            aFileChooserDialog.set_current_name ("");
        }
        aFileChooserDialog.set_default_response (Gtk.ResponseType.ACCEPT);
        if (BookwormApp.Utils.last_file_chooser_path != null && BookwormApp.Utils.last_file_chooser_path.length != 0) {
            try {
                aFileChooserDialog.set_current_folder_file (GLib.File.new_for_path (BookwormApp.Utils.last_file_chooser_path));
            } catch (Error e) {
                warning ("Could not set folder [" + BookwormApp.Utils.last_file_chooser_path + "] for file chooser dialog : " + e.message);
            }
        } else {
            aFileChooserDialog.set_current_folder (GLib.Environment.get_home_dir ());
        }
        aFileChooserDialog.key_press_event.connect ((ev) => {
            if (ev.keyval == 65307) { // Esc key
                aFileChooserDialog.destroy ();
            }
            return false;
        });
        //Set File filters based on the required Filter Type
        switch (filterType) {
            case "EBOOKS":
                Gtk.FileFilter ebook_files_filter = new Gtk.FileFilter ();
                //Add filter for supported eBook formats
                ebook_files_filter.set_filter_name (BookwormApp.Constants.TEXT_FOR_FILE_CHOOSER_FILTER_BOOKS);
                foreach (string pattern in BookwormApp.Constants.FILE_CHOOSER_FILTER_EBOOKS) {
                    ebook_files_filter.add_pattern (pattern);
                }
                aFileChooserDialog.add_filter (ebook_files_filter);
                break;
            case "IMAGES":
                Gtk.FileFilter image_files_filter = new Gtk.FileFilter ();
                //Add filter for supported eBook formats
                image_files_filter.set_filter_name (BookwormApp.Constants.TEXT_FOR_FILE_CHOOSER_FILTER_IMAGES);
                foreach (string pattern in BookwormApp.Constants.FILE_CHOOSER_FILTER_IMAGES) {
                    image_files_filter.add_pattern (pattern);
                }
                aFileChooserDialog.add_filter (image_files_filter);
                break;
            default:
                break;
        }
        //Set the All Files filter
        Gtk.FileFilter all_files_filter = new Gtk.FileFilter ();
        all_files_filter.set_filter_name (BookwormApp.Constants.TEXT_FOR_FILE_CHOOSER_FILTER_ALL_FILES);
        all_files_filter.add_pattern ("*");
        aFileChooserDialog.add_filter (all_files_filter);
        return aFileChooserDialog;
    }

    public static ArrayList<string> selectFileChooser (
        Gtk.FileChooserAction action,
        string title,
        Gtk.Window? parent,
        bool select_multiple,
        string filterType
    ) {
        ArrayList<string> eBookLocationList = new ArrayList<string> ();
        //choose eBook using a File chooser dialog
        Gtk.FileChooserDialog aFileChooserDialog =
            BookwormApp.Utils.new_file_chooser_dialog (
                action, title, parent, select_multiple, filterType);
        aFileChooserDialog.show_all ();
        if (aFileChooserDialog.run () == Gtk.ResponseType.ACCEPT) {
            SList<string> uris = aFileChooserDialog.get_uris ();
            foreach (unowned string uri in uris) {
                eBookLocationList.add (File.new_for_uri (uri).get_path ());
            }
            aFileChooserDialog.close ();
        } else {
            aFileChooserDialog.close ();
        }
        return eBookLocationList;
    }

    public static ArrayList<string> selectDirChooser (
        string title,
        Gtk.Window? parent,
        bool select_multiple
    ) {
        ArrayList<string> selectedDirList = new ArrayList<string> ();
        Gtk.FileChooserDialog aFileChooserDialog = new Gtk.FileChooserDialog (
            title, parent, Gtk.FileChooserAction.SELECT_FOLDER);
        aFileChooserDialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        aFileChooserDialog.add_button (_("Open"), Gtk.ResponseType.ACCEPT);
        aFileChooserDialog.set_default_response (Gtk.ResponseType.ACCEPT);
        if (BookwormApp.Utils.last_file_chooser_path != null &&
            BookwormApp.Utils.last_file_chooser_path.length != 0)
        {
            try {
                aFileChooserDialog.set_current_folder_file (
                    GLib.File.new_for_path (
                        BookwormApp.Utils.last_file_chooser_path));
            } catch (GLib.Error e) {
                warning ("Error in setting the folder [" +
                    BookwormApp.Utils.last_file_chooser_path +
                    "] for the File Chooser Dialog:" + e.message);
            }
        } else {
            aFileChooserDialog.set_current_folder (GLib.Environment.get_home_dir ());
        }
        Gtk.FileFilter all_files_filter = new Gtk.FileFilter ();
        all_files_filter.set_filter_name (BookwormApp.Constants.TEXT_FOR_FILE_CHOOSER_FILTER_ALL_FILES);
        all_files_filter.add_pattern ("*");
        aFileChooserDialog.add_filter (all_files_filter);
        aFileChooserDialog.show_all ();
        if (aFileChooserDialog.run () == Gtk.ResponseType.ACCEPT) {
            SList<string> uris = aFileChooserDialog.get_uris ();
            foreach (unowned string uri in uris) {
                selectedDirList.add (File.new_for_uri (uri).get_path ());
            }
            aFileChooserDialog.close ();
        } else {
            aFileChooserDialog.close ();
        }
        aFileChooserDialog.key_press_event.connect ((ev) => {
            if (ev.keyval == 65307) { // Esc key
                aFileChooserDialog.destroy ();
            }
            return false;
        });
        return selectedDirList;
    }

    public static string parseMarkUp (string inputString) {
        string outputString = "";
        unichar accel_char;
        try {
            Pango.parse_markup (inputString, inputString.length, 0, null, out outputString, out accel_char);
        } catch (GLib.Error e) {
            warning ("Could not parseMarkUp [" + inputString + "]: " + e.message);
            outputString = inputString;
        }
        return outputString;
    }

    public static string decodeHTMLChars (string inputString) {
        string outputString = Soup.URI.decode (inputString);
        return outputString;
    }

    public static string encodeHTMLChars (string inputString) {
        string outputString = inputString.replace ("#", "%23");
        return outputString;
    }

    public static string removeMarkUp (string inputString) {
        string outputString = Soup.URI.decode (inputString);
        //replace the escape char for space present in HTML converted from PDF
        outputString = outputString.replace ("&#160;", " ").replace ("#160;", " ").replace ("&#160", " ");
        return outputString;
    }

    public static string removeTagsFromText (string input) {
        debug ("Starting execution of removeTagsFromText on text:" + input);
        StringBuilder filteredInput = new StringBuilder (input.strip ());
        int posOfStartTag = filteredInput.str.index_of ("<");
        int posOfEndTag = filteredInput.str.index_of (">");
        //handle the case when both start and end tags are present in the right order
        if (posOfStartTag != -1 && posOfEndTag != -1 && posOfEndTag > posOfStartTag) {
            filteredInput.assign (filteredInput.str.replace (
                filteredInput.str.slice (posOfStartTag, posOfEndTag + 1), ""));
        }
        posOfStartTag = filteredInput.str.index_of ("<");
        posOfEndTag = filteredInput.str.index_of (">");
        //handle the case whenboth start and end tags are present but ">" is present before the "<"
        if (posOfStartTag != -1 && posOfEndTag != -1 && posOfStartTag > posOfEndTag) {
            filteredInput.assign (filteredInput.str.replace (
                filteredInput.str.slice (0, posOfEndTag + 1), ""));
        }
        posOfStartTag = filteredInput.str.index_of ("<");
        posOfEndTag = filteredInput.str.index_of (">");
        //handle the case when only ">" is present
        if (posOfEndTag != -1 && posOfStartTag == -1) {
            filteredInput.assign (filteredInput.str.replace (
                filteredInput.str.slice (0, posOfEndTag + 1), ""));
        }
        posOfStartTag = filteredInput.str.index_of ("<");
        posOfEndTag = filteredInput.str.index_of (">");
        //handle the case when when only "<" is present
        if (posOfStartTag != -1 && posOfEndTag == -1) {
            filteredInput.assign (filteredInput.str.replace (
                filteredInput.str.slice (posOfStartTag, filteredInput.str.length), ""));
        }
        if (filteredInput.str.index_of ("<") != -1 || filteredInput.str.index_of (">") != -1) {
            filteredInput.assign (removeTagsFromText (filteredInput.str.strip ()));
        }
        //remove any html escape characters if present
        filteredInput.assign (removeMarkUp (filteredInput.str));
        //remove any line feeds
        filteredInput.assign (filteredInput.str.replace ("\n", ""));
        debug ("Completed execution of removeTagsFromText with text:" + filteredInput.str);
        return filteredInput.str.strip ();
    }

    public static string convertContentListToString (BookwormApp.Book aBook) {
        StringBuilder contentListString = new StringBuilder ("");
        ArrayList<string> contentList = aBook.getBookContentList ();
        foreach (string content in contentList) {
            contentListString.append (content).append ("~~##~~");
        }
        return contentListString.str;
    }

    public static BookwormApp.Book convertStringToContentList (owned BookwormApp.Book aBook, string contentListString) {
        string [] contentListArray = contentListString.split ("~~##~~");
        foreach (string content in contentListArray) {
            if (content != null && content.length > 0) {
                aBook.setBookContentList (content);
            }
        }
        return aBook;
    }

    public static string convertTreeMapToString (TreeMap<string, string> aMap) {
        StringBuilder stringForTreeMap = new StringBuilder ("");
        foreach (var entry in aMap.entries) {
            stringForTreeMap.append (entry.key).append ("~~##~~").append (entry.value);
            stringForTreeMap.append ("~~^^~~");
        }
        return stringForTreeMap.str;
    }

    public static TreeMap<string, string> convertStringToTreeMap (string stringForTreeMap) {
        TreeMap<string, string> treeMap = new TreeMap<string, string> ();
        if (stringForTreeMap.index_of ("~~^^~~") != -1) {
            string [] treeMapArray = stringForTreeMap.split ("~~^^~~");
            foreach (string mapEntry in treeMapArray) {
                if (mapEntry.index_of ("~~##~~") != -1) {
                    string [] keyValPair = mapEntry.split ("~~##~~");
                    treeMap.set (keyValPair[0], keyValPair[1]);
                }
            }
        }
        return treeMap;
    }

    public static string convertTOCToString (BookwormApp.Book aBook) {
        StringBuilder tocString = new StringBuilder ("");
        ArrayList<HashMap<string, string>> tocList = aBook.getTOC ();
        foreach (HashMap<string, string> tocListItemMap in tocList) {
            foreach (var entry in tocListItemMap.entries) {
                tocString.append (entry.key).append ("~~##~~").append (entry.value);
            }
            tocString.append ("~~^^~~");
        }
        return tocString.str;
    }

    public static BookwormApp.Book convertStringToTOC (owned BookwormApp.Book aBook, string tocString) {
        //break the string into TOC List
        string [] tocStringArray = tocString.split ("~~^^~~");
        //add data to the TOC details to the book
        foreach (string tocItemStr in tocStringArray) {
            string [] tocItemStringArray = tocItemStr.split ("~~##~~");
            if (tocItemStringArray.length == 2) {
                HashMap<string, string> tocListItemMap = new HashMap<string, string> ();
                tocListItemMap.set (tocItemStringArray[0], tocItemStringArray[1]);
                aBook.setTOC (tocListItemMap);
            }
        }
        return aBook;
    }

    public static BookwormApp.Book setBookCoverImage (owned BookwormApp.Book aBook, string bookCoverImageLocation) {
        //copy cover image to bookworm cover image location
        string coverImageFileName = File.new_for_commandline_arg (bookCoverImageLocation).get_basename ();
        string coverImageFileExtension = "";
        if (coverImageFileName.index_of (".") != -1) {
            coverImageFileExtension = coverImageFileName.slice (
                coverImageFileName.last_index_of (".") + 1, coverImageFileName.length);
        }
        string bookwormCoverLocation =
            BookwormApp.Bookworm.bookworm_config_path + "/covers/" +
            aBook.getBookId ().to_string () + "_cover." + coverImageFileExtension;
        BookwormApp.Utils.execute_sync_command (
            "cp \"" + bookCoverImageLocation + "\" \"" + bookwormCoverLocation + "\"");
        //cover was extracted from the ebook contents
        aBook.setIsBookCoverImagePresent (true);
        aBook.setBookCoverLocation (bookwormCoverLocation);
        debug ("eBook cover image extracted successfully into location: " + bookwormCoverLocation);
        return aBook;
    }

    public static string setWebViewTitle (string javascript) {
        string selectedText = "";
        debug ("Javascrit for setting Webview Title: " + javascript);
        var loop = new MainLoop ();
        BookwormApp.AppWindow.aWebView.run_javascript.begin (javascript, null, (obj, res) => {
            try {
                BookwormApp.AppWindow.aWebView.run_javascript.end (res);
            } catch (GLib.Error e) {
                warning ("Could not get selected text, javascript error: " + e.message);
            }
            selectedText = BookwormApp.AppWindow.aWebView.get_title ();
            loop.quit ();
        });
        loop.run ();
        debug ("Webview Title set as:" + selectedText);
        return selectedText;
    }

    public static string minimizeStringLength (string originalString, int maxLength) {
        string modifiedString = originalString;
        if (modifiedString.length > maxLength) {
            modifiedString = modifiedString.slice (0, maxLength) + "...";
        }
        return modifiedString;
    }

    public static string breakString (string originalString, int breakLength, string breakString) {
        StringBuilder formattedString = new StringBuilder ("");
        //check if the string is at least as long as the specified break length
        if (originalString.length > breakLength) {
            StringBuilder extractedString = new StringBuilder ("");
            int charCount = 0;
            //loop until there are enough chars left in the string
            while ((charCount < originalString.length) && ((originalString.length - charCount) > breakLength)) {
                //extract specified chars from the strings
                extractedString.assign ("");
                extractedString.assign (originalString.slice (charCount, charCount + breakLength));
                //check if there if a occurence of the break string in the extracted string
                if (extractedString.str.index_of (breakString) != -1) {
                    //the extracted string has a break - continue checking
                    formattedString.append (extractedString.str);
                } else {
                    //the extracted string does not have a break - introduce the break
                    formattedString.append (extractedString.str).append (breakString);
                }
                charCount = charCount + breakLength;
            }
            //append any left over chars
            formattedString.append (originalString.slice (charCount, originalString.length));
        } else {
            formattedString.append (originalString);
        }
        return formattedString.str;
    }
}
