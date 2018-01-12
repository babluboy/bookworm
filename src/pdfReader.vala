/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and is used for parsing PDF file formats
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

using Poppler;
public class BookwormApp.pdfReader {

  public static BookwormApp.Book parsePDFBook (owned BookwormApp.Book aBook) throws GLib.Error{
    //Only parse the eBook if it has not been parsed already
    if(!aBook.getIsBookParsed()){
      debug("Initiated process for parsing of PDF Book located at:"+aBook.getBookLocation());
      //Extract the content of the PDF
      string extractionLocation = extractEBook(aBook.getBookLocation());
      if("false" == extractionLocation){ //handle error condition
        aBook.setIsBookParsed(false);
        aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_EXTRACTION_ISSUE);
        return aBook;
      }else{
        aBook.setBookExtractionLocation(extractionLocation);
      }

      //Split the single HTML file into multiple file by sections
      aBook = getContentList(aBook, extractionLocation);
      if(aBook.getBookContentList().size < 1){
        //No content has been determined for the book
        aBook.setIsBookParsed(false);
        aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_EXTRACTION_ISSUE);
        return aBook;
      }

      //Try to determine Book Cover Image if it is not already available
      if(!aBook.getIsBookCoverImagePresent()){
        aBook = setCoverImage(aBook);
      }

      //Determine Book Meta Data like Title, Author, etc
      aBook = setBookMetaData(aBook);

      aBook.setIsBookParsed(true);
      debug ("Sucessfully parsed PDF Book located at:"+aBook.getBookLocation());
    }
    return aBook;
  }

  public static string extractEBook(string eBookLocation){
        string extractionLocation = "false";
         debug("Initiated process for content extraction of PDF Book located at:"+eBookLocation);
        if(BookwormApp.Bookworm.settings == null){
            BookwormApp.Bookworm.settings = BookwormApp.Settings.get_instance();
        }
        //create a location for extraction of eBook based on local storage prefference
        if(BookwormApp.Bookworm.settings.is_local_storage_enabled){
            extractionLocation = BookwormApp.Bookworm.bookworm_config_path + "/books/" + File.new_for_path(eBookLocation).get_basename();
        }else{
            extractionLocation = BookwormApp.Constants.EBOOK_EXTRACTION_LOCATION + File.new_for_path(eBookLocation).get_basename();
        }
        //check and create directory for extracting contents of ebook
        BookwormApp.Utils.fileOperations("CREATEDIR", extractionLocation, "", "");
        //extract eBook contents into temp location
        BookwormApp.Utils.execute_async_multiarg_command_pipes({"pdftohtml",
                                                              "-noframes",
                                                              "-zoom", "2.0",
                                                              "-wbt", "20.0",
                                                              "-nomerge",
                                                              eBookLocation,
                                                              extractionLocation + "/" + File.new_for_path(eBookLocation).get_basename()+".html"
                                                            });

        debug("Output of pdftohtml command:"+BookwormApp.Utils.spawn_async_with_pipes_output.str);
        debug("eBook contents extracted sucessfully into location:"+extractionLocation);
        return extractionLocation;
  }

  public static BookwormApp.Book getContentList (owned BookwormApp.Book aBook, string extractionLocation){
    string extractedHTMLFilePath = extractionLocation + "/" + File.new_for_path(aBook.getBookLocation()).get_basename()+".html";
    File htmlFile = File.new_for_path (extractedHTMLFilePath);
    //Check if the extracted html file exists
    if (!htmlFile.query_exists ()) {
      aBook.setIsBookParsed(false);
      aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_EXTRACTION_ISSUE);
      return aBook;
    }

    try {
        // Clear the content list of any previous items
        aBook.clearBookContentList();
        // Open file for reading and wrap returned FileInputStream into a
        // DataInputStream, so we can read line by line
        var dis = new DataInputStream (htmlFile.read ());
        string line = "";
        int countOfSections = 1;
        string htmlStartContent = "<html><body>";
        StringBuilder htmlSection = new StringBuilder(htmlStartContent);
        // Read lines until end of file (null) is reached
        while ((line = dis.read_line (null)) != null) {
            //split the large html file based on occurence of <hr/>
            if("<hr/>".up() == line.up()){
              htmlSection.append("</body></html>");
              BookwormApp.Utils.fileOperations("WRITE", extractionLocation,
                                               File.new_for_path(aBook.getBookLocation()).get_basename()+"_"+countOfSections.to_string()+".html",
                                               htmlSection.str);
              aBook.setBookContentList(extractionLocation + "/" + File.new_for_path(aBook.getBookLocation()).get_basename()+"_"+countOfSections.to_string()+".html");
              countOfSections++;
              htmlSection.assign(htmlStartContent);
            }else{
              //keep appending data until occurence of <hr/>
              htmlSection.append(line);
            }
        }
    } catch (GLib.Error e) {
      info ("%s", e.message);
      warning("Problem in Content splitting for PDF Book ["+aBook.getBookLocation()+"]:%s"+e.message);
      aBook.setIsBookParsed(false);
      aBook.setParsingIssue(BookwormApp.Constants.TEXT_FOR_EXTRACTION_ISSUE);
      return aBook;
    }
    return aBook;
  }

  public static BookwormApp.Book setCoverImage(owned BookwormApp.Book aBook){
        string bookCoverLocation = "";
        //get the first html section
        if(aBook.getBookContentList() != null && aBook.getBookContentList().size > 0){
            string htmlForCover = BookwormApp.Utils.fileOperations("READ_FILE", aBook.getBookContentList().get(0), "", "");
            if(htmlForCover.index_of("<img src=\"") != -1){
              int startPosOfCoverImage = htmlForCover.index_of("<img src=\"") + ("<img src=\"").length;
              int endPosOfCoverImage = htmlForCover.index_of("\"/>", startPosOfCoverImage);
              if(startPosOfCoverImage != -1 && endPosOfCoverImage != -1 && endPosOfCoverImage > startPosOfCoverImage){
                    bookCoverLocation = htmlForCover.slice(startPosOfCoverImage, endPosOfCoverImage);
              }
              if(bookCoverLocation == null || bookCoverLocation.length < 1){
                    aBook.setIsBookCoverImagePresent(false);
                    debug("Cover image not found for book located at:"+aBook.getBookExtractionLocation());
              }else{
                    //copy cover image to bookworm cover image cache
                    aBook = BookwormApp.Utils.setBookCoverImage(aBook, bookCoverLocation);
              }
            }
        }else{
            aBook.setIsBookCoverImagePresent(false);
            debug("Cover image not found for book located at:"+aBook.getBookExtractionLocation());
        }
        return aBook;
  }

  public static BookwormApp.Book setBookMetaData(owned BookwormApp.Book aBook){
    string bookTitle = "";
    Document pdfDocument = null;
    try{
      //determine the title of the book if it is not already available
      debug("Initiated process for title of eBook located at:"+aBook.getBookExtractionLocation());
      if(aBook.getBookTitle() != null && aBook.getBookTitle().length < 1){
        pdfDocument = new Document.from_gfile(File.new_for_path(aBook.getBookLocation()), null);
        bookTitle = pdfDocument.get_title();
        if(bookTitle != null && bookTitle.length > 0){
          aBook.setBookTitle(bookTitle);
          debug("Determined Title as:" + bookTitle + " for book located at:"+aBook.getBookExtractionLocation());
        }else{
          //If the book title has not been determined, use the file name as book title
          bookTitle = File.new_for_path(aBook.getBookLocation()).get_basename();
          if(bookTitle.last_index_of(".") != -1){
            bookTitle = bookTitle.slice(0, bookTitle.last_index_of("."));
          }
          aBook.setBookTitle(bookTitle);
        }
      }
    } catch(GLib.Error e){
      info ("Error while checking title in PDF book: %s\n", e.message);
      //Set book title based on file name
      bookTitle = File.new_for_path(aBook.getBookLocation()).get_basename();
      if(bookTitle.last_index_of(".") != -1){
        bookTitle = bookTitle.slice(0, bookTitle.last_index_of("."));
      }
      aBook.setBookTitle(bookTitle);
    }
     //determine the table of contents of the book
    /*debug("Initiated process for table of contents of eBook located at:"+aBook.getBookExtractionLocation());
    try {
        debug(pdfDocument.get_metadata ());
        var iterp = new Poppler.IndexIter(pdfDocument);
        if(iterp != null) {
            bool isIterRemaning = true;
            while(isIterRemaning) {
                var link = iterp.get_action();
                int pageNumber = link.goto_dest.dest.page_num;
                var page = pdfDocument.get_page(link.goto_dest.dest.page_num);
                debug("Chapter Name:"+link.goto_dest.title+" | Page Number:"+pageNumber.to_string()+ " | Page Label:"+page.get_label()+ "| " +"\n");
                //GLib.List<Poppler.Rectangle>? rectangle_list = page.find_text(page.get_label());
                page.find_text(link.goto_dest.title).foreach ((entry) => {
		            debug ("Rectangle Info:"+entry.x1.to_string());
	            });
                isIterRemaning = iterp.next();
            }
        }
    } catch(GLib.Error e){
      info ("Error while checking table of contents in PDF book: %s\n", e.message);

    }*/

    return aBook;
  }
}
