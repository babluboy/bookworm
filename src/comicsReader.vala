/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and is used for parsing comics
* file formats like .cbz, .cbr
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
public class BookwormApp.comicsReader {
  public static BookwormApp.Book parseComicsBook (owned BookwormApp.Book aBook, string comicsFileType){
    //Only parse the eBook if it has not been parsed already
    if(!aBook.getIsBookParsed()){
      //Extract the content of the comics book based on file type
      string extractionLocation = extractComics(aBook.getBookLocation(),comicsFileType);
      if("false" == extractionLocation){ //handle error condition
        aBook.setIsBookParsed(false);
        aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_EXTRACTION_ISSUE);
        return aBook;
      }else{
        aBook.setBookExtractionLocation(extractionLocation);
      }
      //Store the list of comic book images in the correct order of reading
      aBook = getContentList(aBook, extractionLocation);

    }
    //Use the file name as book title
    if(aBook.getBookTitle() != null && aBook.getBookTitle().length < 1){
      string bookTitle = File.new_for_path(aBook.getBookLocation()).get_basename();
      if(bookTitle.last_index_of(".") != -1){
        bookTitle = bookTitle.slice(0, bookTitle.last_index_of("."));
      }
      aBook.setBookTitle(bookTitle);
      debug("File name set as Title:"+bookTitle);
    }

    aBook.setIsBookParsed(true);
    debug ("Sucessfully parsed Comic Book located at:"+aBook.getBookLocation());
    return aBook;
  }

  public static string extractComics(string eBookLocation, string comicsFileType){
    string extractionLocation = "";
    try{
      debug("Initiated process for content extraction of CBR Comics Book located at:"+eBookLocation);
      //create a location for extraction of eBook based on local storage prefference
      if(BookwormApp.Bookworm.settings.is_local_storage_enabled){
        extractionLocation = BookwormApp.Bookworm.bookworm_config_path + "/books/" + File.new_for_path(eBookLocation).get_basename();
      }else{
        extractionLocation = BookwormApp.Constants.EBOOK_EXTRACTION_LOCATION + File.new_for_path(eBookLocation).get_basename();
      }
      //check and create directory for extracting contents of ebook
      BookwormApp.Utils.fileOperations("CREATEDIR", extractionLocation, "", "");
      //extract eBook contents into extraction location
      switch(comicsFileType){
        case ".CBR":
          BookwormApp.Utils.execute_sync_command("unrar e \"" + eBookLocation + "\" \""+ extractionLocation + "/images/" +"\"");
          break;
        case ".CBZ":
          BookwormApp.Utils.execute_sync_command("unzip -j -o \"" + eBookLocation + "\" -d \""+ extractionLocation + "/images/" +"\"");
          break;
        default:
          break;
      }
    }catch(GLib.Error e){
      warning("Problem in Content Extraction for Comics Book ["+eBookLocation+"]:%s"+e.message);
      return "false";
    }
    debug("Comics contents extracted sucessfully into location:"+extractionLocation);
    return extractionLocation;
  }

  public static BookwormApp.Book getContentList (owned BookwormApp.Book aBook, string extractionLocation){
    //list the content of the extraction folder
    string comicContent = BookwormApp.Utils.execute_sync_command("ls -1 \"" + extractionLocation + "/images/" + "\"");
    comicContent = comicContent.replace("\r", "^^^").replace("\n", "^^^");
    string[] comicContentList = comicContent.split("^^^");
    if(comicContentList.length > 1){
      string htmlTemplate = "<html><style>img{max-width: 100%;height: auto;}</style><body><img src=\"<image-location>\"></body></html>";
      int countOfSections = 1;
      StringBuilder htmlFileName = new StringBuilder();
      foreach (string contentLocationPath in comicContentList) {
        //TO-DO: Add a better logic to list pages by page number in file name
        if(contentLocationPath != null && contentLocationPath.length > 0){
          //create a HTML content with the location of the image
          htmlFileName.assign(File.new_for_path(aBook.getBookLocation()).get_basename()+"_"+countOfSections.to_string()+".html");
          BookwormApp.Utils.fileOperations("WRITE", extractionLocation,
                                           htmlFileName.str, htmlTemplate.replace("<image-location>", extractionLocation + "/images/" + contentLocationPath));
          aBook.setBookContentList(extractionLocation + "/" + htmlFileName.str);
          //Set the first image as the cover for the comics
          if(countOfSections == 1){
            if(!aBook.getIsBookCoverImagePresent()){
              debug("setting cover as:"+extractionLocation + "/images/" + contentLocationPath);
              aBook = BookwormApp.Utils.setBookCoverImage(aBook, extractionLocation + "/images/" + contentLocationPath);
            }
          }
          countOfSections++;
        }else{
          aBook.setIsBookParsed(false);
          aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_EXTRACTION_ISSUE);
        }
      }
    }
		return aBook;
	}

}
