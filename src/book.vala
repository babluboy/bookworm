/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm.
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

public class BookwormApp.Book{

  private string bookLocation = "";
  private string bookCoverLocation = "";
  private string bookExtractionLocation = "";
  private string bookTitle = "";
  private string opfFileLocation = "";
  private string baseLocationOfContents = "";
  private bool isBookCoverImagePresent = false;
  private int bookPageNumber = -1;
  private bool ifPageForward = true;
  private bool ifPageBackward = true;
  private Gee.ArrayList<string> bookContentList = new Gee.ArrayList<string> ();


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
  public Gee.ArrayList<string> getBookContentList (){
    return bookContentList;
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
}
