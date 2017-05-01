/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and has the getter/setter methods
* used for holding the state of the book
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
public class BookwormApp.Book{

  private int bookId = 0;
  private bool isBookParsedCorrectly = false;
  private string parsingIssue = "";
  private string bookLocation = "";
  private string bookCoverLocation = "";
  private string bookExtractionLocation = "";
  private string bookTitle = "";
  private string bookAuthor = "";
  private string bookTags = "";
  private string bookPublishDate = "";
  private string bookCreationDate = "";
  private string bookLastModificationDate = "";
  private int bookRating = 1;

  private string opfFileLocation = "";
  private string baseLocationOfContents = "";
  private bool isBookCoverImagePresent = false;
  private int bookPageNumber = -1;
  private bool ifPageForward = true;
  private bool ifPageBackward = true;
  private bool isBookSelected = false;
  private bool wasBookOpened = false;
  private HashMap<string,Gtk.Widget> bookWidgetsList = new HashMap<string,Gtk.Widget> ();
  private ArrayList<string> bookContentList = new ArrayList<string> ();
  private ArrayList<HashMap<string,string>> TOCMap = new ArrayList<HashMap<string,string>>();
  private StringBuilder bookmarks = new StringBuilder ("");

  //getter list for book id
  public void setBookId (int aBookId){
    bookId = aBookId;
  }
  public int getBookId (){
    return bookId;
  }

  //getter list for isBookParsedCorrectly
  public void setIsBookParsed (bool isParsed){
    isBookParsedCorrectly = isParsed;
  }
  public bool getIsBookParsed (){
    return isBookParsedCorrectly;
  }

  //getter list for book location
  public void setParsingIssue (string aParsingIssue){
    parsingIssue = aParsingIssue;
  }
  public string getParsingIssue (){
    return parsingIssue;
  }

  //getter list for book location
  public void setBookLocation (string aBookLocation){
    bookLocation = aBookLocation;
  }
  public string getBookLocation (){
    return bookLocation;
  }

  //getter list for book cover image location
  public void setBookCoverLocation (string aBookCoverLocation){
    bookCoverLocation = aBookCoverLocation;
  }
  public string getBookCoverLocation (){
    return bookCoverLocation;
  }

  //getter setter for content list of book parts
  public void setBookContentList (string contentList){
    bookContentList.add(contentList);
  }
  public ArrayList<string> getBookContentList (){
    return bookContentList;
  }

  //getter setter for Table Of Contents
  public void setTOC (HashMap<string,string> toc){
    TOCMap.add(toc);
  }
  public ArrayList<HashMap<string,string>> getTOC (){
    return TOCMap;
  }

  //getter setter for temp location of ebook contents
  public void setBookExtractionLocation (string aBookExtractionLocation){
    bookExtractionLocation = aBookExtractionLocation;
  }
  public string getBookExtractionLocation (){
    return bookExtractionLocation;
  }

  //getter setter for book title
  public void setBookTitle (string aBookTitle){
    bookTitle = aBookTitle;
  }
  public string getBookTitle (){
    return bookTitle;
  }

  //getter list for book rating
  public void setBookRating (int aBookRating){
    bookRating = aBookRating;
  }
  public int getBookRating (){
    return bookRating;
  }

  //getter setter for book author
  public void setBookAuthor (string aBookAuthor){
    bookAuthor = aBookAuthor;
  }
  public string getBookAuthor (){
    return bookAuthor;
  }

  //getter setter for book tags
  public void setBookTags (string aBookTags){
    bookTags = aBookTags;
  }
  public string getBookTags (){
    return bookTags;
  }


  //getter setter for location of books OPF file
  public void setOPFFileLocation (string aOPFFileLocation){
    opfFileLocation = aOPFFileLocation;
  }
  public string getOPFFileLocation (){
    return opfFileLocation;
  }

  //getter setter for base location of eBook file contents
  public void setBaseLocationOfContents (string aBaseLocationOfContents){
    baseLocationOfContents = aBaseLocationOfContents;
  }
  public string getBaseLocationOfContents (){
    return baseLocationOfContents;
  }

  //getter setter for presence of Cover Location
  public void setIsBookCoverImagePresent (bool isABookCoverImagePresent){
    isBookCoverImagePresent = isABookCoverImagePresent;
  }
  public bool getIsBookCoverImagePresent (){
    return isBookCoverImagePresent;
  }

  //getter list for book location
  public void setBookPublishDate (string aBookPublishDate){
    bookPublishDate = aBookPublishDate;
  }
  public string getBookPublishDate (){
    return bookPublishDate;
  }

  //getter list for book location
  public void setBookCreationDate (string aBookCreationDate){
    bookCreationDate = aBookCreationDate;
  }
  public string getBookCreationDate (){
    return bookCreationDate;
  }

  //getter list for book location
  public void setBookLastModificationDate (string aBookLastModificationDate){
    bookLastModificationDate = aBookLastModificationDate;
  }
  public string getBookLastModificationDate (){
    return bookLastModificationDate;
  }

  //getter setter for eBook pageNumber
  public void setBookPageNumber (int aBookPageNumber){
    bookPageNumber = aBookPageNumber;
  }
  public int getBookPageNumber (){
    return bookPageNumber;
  }

  //getter setter if eBook pageForward is possible
  public void setIfPageForward (bool ifBookPageForward){
    ifPageForward = ifBookPageForward;
  }
  public bool getIfPageForward (){
    return ifPageForward;
  }

  //getter setter if eBook pageBackward is possible
  public void setIfPageBackward (bool ifBookPageBackward){
    ifPageBackward = ifBookPageBackward;
  }
  public bool getIfPageBackward (){
    return ifPageBackward;
  }

  //getter setter for determining if the book is selected
  public void setIsBookSelected  (bool aIsBookSelected){
    isBookSelected = aIsBookSelected;
  }
  public bool getIsBookSelected (){
    return isBookSelected;
  }

  //getter setter for determining if the book was read in this session
  public void setWasBookOpened  (bool aWasBookOpened){
    wasBookOpened = aWasBookOpened;
  }
  public bool getWasBookOpened (){
    return wasBookOpened;
  }

  //getter setter for bookmarks
  public void setBookmark (int pageNumber, string action){
    if("ACTIVE_CLICKED" == action){
      bookmarks.assign(bookmarks.str.replace("**"+pageNumber.to_string()+"**", ""));
    }
    if("INACTIVE_CLICKED" == action){
      bookmarks.append("**"+pageNumber.to_string()+"**");
    }
    if(pageNumber == -10){ //this is used to set the bookmark fetched from the DB
      //set -10 as the "pageNumber" and the book mark data as "action" when setting this value from the DB
      bookmarks.assign(action);
    }
  }
  public string getBookmark (){
    return bookmarks.str;
  }

  //getter setter for list of Gtk Widgets used for a Book
  public void setBookWidget (string name, Gtk.Widget aWidget){
    bookWidgetsList.set(name, aWidget);
  }
  public Gtk.Widget getBookWidget (string name){
    return bookWidgetsList.get(name);
  }

  //print book details
  public string to_string(){
    StringBuilder bookDetails = new StringBuilder();
            bookDetails.append("bookId=").append(bookId.to_string()).append(",\n")
           .append("bookLocation=").append(bookLocation).append(",\n")
           .append("bookCoverLocation=").append(bookCoverLocation).append(",\n")
           .append("bookExtractionLocation=").append(bookExtractionLocation).append(",\n")
           .append("bookTitle="+bookTitle).append(",\n")
           .append("opfFileLocation=").append(opfFileLocation).append(",\n")
           .append("baseLocationOfContents=").append(baseLocationOfContents).append(",\n")
           .append("bookPublishDate="+bookPublishDate).append(",\n")
           .append("isBookCoverImagePresent=").append(isBookCoverImagePresent.to_string()).append(",\n")
           .append("bookCreationDate=").append(bookCreationDate).append(",\n")
           .append("bookLastModificationDate=").append(bookLastModificationDate).append(",\n")
           .append("bookPageNumber=").append(bookPageNumber.to_string()).append(",\n")
           .append("ifPageForward=").append(ifPageForward.to_string()).append(",\n")
           .append("ifPageBackward=").append(ifPageBackward.to_string()).append(",\n")
           .append("bookmarks=").append(bookmarks.str).append(",\n")
           .append("author=").append(bookAuthor).append(",\n")
           .append("ratings=").append(bookRating.to_string()).append(",\n")
           .append("bookContentList=");
     for (int i=0; i<bookContentList.size;i++) {
        bookDetails.append("["+i.to_string()+"]="+bookContentList.get(i)+",");
     }
     return bookDetails.str;
  }
}
