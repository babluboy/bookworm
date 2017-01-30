public class BookwormApp.ePubReader : WebKit.WebView {

  public static string baseLocationOfContents = "";
  public static int currentPageNumber = -1;
  public static WebKit.WebView aWebView;
  public static Gee.ArrayList<string> readingListData = new Gee.ArrayList<string>();
  public static string bookTitle = "";

  public static ePubReader(){
      WebKit.Settings webkitSettings = new WebKit.Settings();
      webkitSettings.set_allow_file_access_from_file_urls (true);
      webkitSettings.set_default_font_family("droid sans");
      webkitSettings.set_allow_universal_access_from_file_urls(true);
      webkitSettings.set_auto_load_images(true);

      aWebView = new WebKit.WebView.with_settings(webkitSettings);
  }

  public WebKit.WebView getWebView (){
    return aWebView;
  }

  public static bool parseEPubBook (string baseExtractedBookPath){
    try{
      //ensure correct mime type in mimetype file
      string ePubMimeContents = BookwormApp.Utils.fileOperations("READ", baseExtractedBookPath, BookwormApp.Constants.EPUB_MIME_SPECIFICATION_FILENAME, "");
      debug("Mime Contents in file :"+baseExtractedBookPath+"/"+BookwormApp.Constants.EPUB_MIME_SPECIFICATION_FILENAME+" is:"+ ePubMimeContents);
      if(ePubMimeContents.strip() != BookwormApp.Constants.EPUB_MIME_SPECIFICATION_CONTENT){
          debug("Mime Contents in file :"+baseExtractedBookPath+"/"+BookwormApp.Constants.EPUB_MIME_SPECIFICATION_FILENAME+" is not :"+ BookwormApp.Constants.EPUB_MIME_SPECIFICATION_CONTENT);
          return false;
      }
      //read the META-INF/container.xml file
      string metaInfContents = BookwormApp.Utils.fileOperations("READ", baseExtractedBookPath, BookwormApp.Constants.EPUB_META_INF_FILENAME, "");
      debug("META-INF Contents in file :"+ baseExtractedBookPath+"/"+BookwormApp.Constants.EPUB_META_INF_FILENAME+" is:"+ metaInfContents);
      //locate the path to the contents
      int startPosOfContentData = metaInfContents.index_of("<rootfile full-path=\"")+("<rootfile full-path=\"").length;
      int endOfPosContentData = metaInfContents.index_of("\"", startPosOfContentData+1);
      string contentLocationPath = metaInfContents.slice(startPosOfContentData,endOfPosContentData);
      debug("Root file full path in file :"+ baseExtractedBookPath+"/"+BookwormApp.Constants.EPUB_META_INF_FILENAME+" is:"+ contentLocationPath);
      //read contents from Content.opf
      string OpfContents = BookwormApp.Utils.fileOperations("READ", baseExtractedBookPath, contentLocationPath, "");
      //determine the title of the bookworm
      if(OpfContents.contains("<dc:title>") && OpfContents.contains("</dc:title>")){
        bookTitle = OpfContents.slice(OpfContents.index_of("<dc:title>")+"<dc:title>".length, OpfContents.index_of("</dc:title>"));
      }
      //determine the base location from the location of the OPF file
      baseLocationOfContents = baseExtractedBookPath+"/"+contentLocationPath;
      baseLocationOfContents = baseLocationOfContents.slice(0, baseLocationOfContents.last_index_of("/"));
      debug("Final Base path for content files:"+baseLocationOfContents);
      //read contents from spine and manifest and populate reading ArrayList
      string spineData = BookwormApp.Utils.extractXMLTag(OpfContents, "<spine", "</spine>");
      //debug("Spine Data:"+spineData);
      string manifestData = BookwormApp.Utils.extractXMLTag(OpfContents, "<manifest", "</manifest>");
      //debug("Manifest Data:"+manifestData);
      int positionOfSpineItemref = 0;
      int positionOfManifestItemref = 0;
      int positionOfManifestDataStart = 0;
      int positionOfManifestDataEnd = 0;
      StringBuilder bufferForSpineDataExtraction = new StringBuilder("");
      StringBuilder bufferForManifestDataExtraction = new StringBuilder("");
      //loop through all itemref elements in spine and determine respective locations
      while (positionOfSpineItemref != -1){
        bufferForSpineDataExtraction.erase(0, -1);
        if(positionOfSpineItemref > 0){ //condition to ignore the first position
          bufferForSpineDataExtraction.append(spineData.slice(positionOfSpineItemref+16, spineData.index_of("\"", positionOfSpineItemref+17)));
          debug("Extracted Spine idref:"+bufferForSpineDataExtraction.str);
          //find the item in manifest matching the spine itemref
          //loop through all item ids in the manifest
          while (positionOfManifestItemref != -1){
            bufferForManifestDataExtraction.erase(0, -1);
            bufferForManifestDataExtraction.append(manifestData.slice(manifestData.index_of("<item", positionOfManifestItemref), manifestData.index_of("\"/>", positionOfManifestItemref)));
            debug("Extracted Manifest Data="+bufferForManifestDataExtraction.str);
            //match spine idref to manifest item id
            if(bufferForManifestDataExtraction.str.contains("id=\""+bufferForSpineDataExtraction.str+"\"")){
              //add manifest location item to array list in order of reading
              positionOfManifestDataStart = bufferForManifestDataExtraction.str.index_of("href=\"")+6;
              positionOfManifestDataEnd = bufferForManifestDataExtraction.str.index_of("\"", bufferForManifestDataExtraction.str.index_of("href=\"")+8);
              readingListData.add (baseLocationOfContents+"/"+bufferForManifestDataExtraction.str.slice(positionOfManifestDataStart, positionOfManifestDataEnd));
              debug("Extracted content location:"+bufferForManifestDataExtraction.str.slice(positionOfManifestDataStart, positionOfManifestDataEnd));
              break;
            }
            positionOfManifestItemref = manifestData.index_of ("<item", positionOfManifestItemref+5);
          }
          positionOfManifestItemref = 0;
        }
        positionOfSpineItemref = spineData.index_of ("<itemref idref=", positionOfSpineItemref+1);
      }
      return true;
    }catch(Error e){
      warning("Failure in parsing ePub book ["+baseExtractedBookPath+"] : "+e.message);
      return false;
    }
  }


  public static bool prepareBookForReading(Gtk.Window window){
    string eBookLocation = "";
    string extractionLocation = BookwormApp.Constants.EPUB_EXTRACTION_LOCATION;
    //choose eBook using a File chooser dialog
    Gtk.FileChooserDialog aFileChooserDialog = BookwormApp.Utils.new_file_chooser_dialog (Gtk.FileChooserAction.OPEN, "Select eBook", window, false);
    aFileChooserDialog.show_all ();
    if (aFileChooserDialog.run () == Gtk.ResponseType.ACCEPT) {
      eBookLocation = aFileChooserDialog.get_filename();
      extractionLocation = extractionLocation + aFileChooserDialog.get_file().get_basename();
      debug("Choosen File = "+eBookLocation);
      BookwormApp.Utils.last_file_chooser_path = aFileChooserDialog.get_current_folder();
      debug("Last visited folder for FileChooserDialog set as:"+BookwormApp.Utils.last_file_chooser_path);
      aFileChooserDialog.destroy();
    }else{
      aFileChooserDialog.destroy();
      return false;
    }

    //check and create directory for extracting contents of ebook
    BookwormApp.Utils.fileOperations("CREATEDIR", extractionLocation, "", "");
    //unzip eBook contents into temp location
    BookwormApp.Utils.execute_sync_command("unzip -o \"" + eBookLocation + "\" -d \""+ extractionLocation +"\"");
    parseEPubBook (extractionLocation);
    return true;
  }

  public static int pageChange (WebKit.WebView aWebView, int pageNumber){
      currentPageNumber = pageNumber;
      string contents = BookwormApp.Utils.fileOperations("READ_FILE", BookwormApp.ePubReader.readingListData.get(currentPageNumber), "", "");
      if(contents.index_of("<img src=\"") != -1){
        contents = contents.replace("<img src=\"","<img src=\""+baseLocationOfContents+"/");
      }else{
        contents = contents.replace("src=\"","src=\""+baseLocationOfContents+"/");
      }
      contents = contents.replace("xlink:href=\"","xlink:href=\""+baseLocationOfContents+"/");
      debug("page="+currentPageNumber.to_string()+", location="+BookwormApp.ePubReader.readingListData.get(currentPageNumber));
      aWebView.load_html(contents, "file:///");
      return 0;
  }
}
