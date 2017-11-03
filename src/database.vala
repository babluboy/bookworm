/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and manages all the Database interactions
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

using Sqlite;
using Gee;

public class BookwormApp.DB{
  public static const string BOOKWORM_TABLE_BASE_NAME = "BOOK_LIBRARY_TABLE";
  public static const string BOOKWORM_TABLE_VERSION = "6"; //Only integers allowed
  public static const string BOOKMETADATA_TABLE_BASE_NAME = "BOOK_METADATA_TABLE";
  public static const string BOOKMETADATA_TABLE_VERSION = "1"; //Only integers allowed
  public static const string VERSION_TABLE_BASE_NAME = "VERSION_TABLE";
  public static const string VERSION_TABLE_VERSION = "1"; //Only integers allowed
  private static Sqlite.Database bookwormDB;
  private static string errmsg;
  private static string queryString;
  private static int executionStatus;

  public static bool initializeBookWormDB(string bookworm_config_path){
    Statement stmt;
    debug("Checking BookWorm DB or creating it if the DB does not exist...");
    int dbOpenStatus = Database.open_v2 (bookworm_config_path+"/bookworm.db",
                                      out bookwormDB, Sqlite.OPEN_READWRITE | Sqlite.OPEN_CREATE);
    if (dbOpenStatus != Sqlite.OK) {
      warning ("Error in opening database["+bookworm_config_path+"/bookworm.db"+"]: %d: %s\n",
                                            bookwormDB.errcode (), bookwormDB.errmsg ()
              );
      return false;
    } else {
        debug ("Sucessfully checked/created DB for Bookworm.....");
    }

    debug ("Creating latest version for Library table if it does not exists");
    queryString = "CREATE TABLE IF NOT EXISTS "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" ("
                   + "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                   + "BOOK_LOCATION TEXT NOT NULL DEFAULT '', "
                   + "BOOK_TITLE TEXT NOT NULL DEFAULT '', "
                   + "BOOK_AUTHOR TEXT NOT NULL DEFAULT '', "
                   + "BOOK_COVER_IMAGE_LOCATION TEXT NOT NULL DEFAULT '', "
                   + "IS_BOOK_COVER_IMAGE_PRESENT TEXT NOT NULL DEFAULT '', "
                   + "BOOK_PUBLISH_DATE TEXT NOT NULL DEFAULT '', "
                   + "BOOK_TOTAL_NUMBER_OF_PAGES TEXT NOT NULL DEFAULT '', "
                   + "BOOK_LAST_READ_PAGE_NUMBER TEXT NOT NULL DEFAULT '', "
                   + "BOOK_TOTAL_PAGES TEXT NOT NULL DEFAULT '', " //Added in table v6
                   + "TAGS TEXT NOT NULL DEFAULT '', " //Added in table v3
                   + "ANNOTATION_TAGS TEXT NOT NULL DEFAULT '', " //Added in table v7
                   + "RATINGS TEXT NOT NULL DEFAULT '', " //Added in table v3
                   + "CONTENT_EXTRACTION_LOCATION TEXT NOT NULL DEFAULT '', " //Added in table v4
                   + "creation_date INTEGER,"
                   + "modification_date INTEGER)";
		executionStatus = bookwormDB.exec (queryString, null, out errmsg);
	 	if (executionStatus != Sqlite.OK) {
      debug("Error on executing Query:"+queryString);
	 		warning ("Error details: %s\n", errmsg);
      return false;
	 	} else {
      debug("Sucessfully checked/created table:"+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION);
    }

    debug ("Creating latest version for Book Metadata table if it does not exists");
    queryString = "CREATE TABLE IF NOT EXISTS "+BOOKMETADATA_TABLE_BASE_NAME+BOOKMETADATA_TABLE_VERSION+" ("
                   + "id INTEGER PRIMARY KEY, "
                   + "BOOK_TOC_DATA TEXT NOT NULL DEFAULT '', "
                   + "BOOKMARKS TEXT NOT NULL DEFAULT '', "
                   + "CONTENT_DATA_LIST TEXT NOT NULL DEFAULT '', "
                   + "BOOK_LAST_SCROLL_POSITION TEXT NOT NULL DEFAULT '', "
                   + "BOOK_ANNOTATIONS TEXT NOT NULL DEFAULT '', "
									 + "creation_date INTEGER,"
                   + "modification_date INTEGER)";
		executionStatus = bookwormDB.exec (queryString, null, out errmsg);
	 	if (executionStatus != Sqlite.OK) {
      debug("Error on executing Query:"+queryString);
	 		warning ("Error details: %s\n", errmsg);
      return false;
	 	} else {
      debug("Sucessfully checked/created table:"+BOOKMETADATA_TABLE_BASE_NAME+BOOKMETADATA_TABLE_VERSION);
    }

    //Check details of tables in DB
    ArrayList<string> listOfTables = new ArrayList<string> ();
    queryString = "SELECT NAME FROM SQLITE_MASTER WHERE TYPE='table' ORDER BY NAME";
    executionStatus = bookwormDB.prepare_v2 (queryString, queryString.length, out stmt);
    if (executionStatus != Sqlite.OK) {
      debug("Error on executing Query:"+queryString);
	 		warning ("Error details: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
	 	}
    while (stmt.step () == ROW) {
      listOfTables.add(stmt.column_text (0).strip());
    }
    stmt.reset ();

    //Remove the current tables (latest versions) from the list
    listOfTables.remove(BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION);
    listOfTables.remove(BOOKMETADATA_TABLE_BASE_NAME+BOOKMETADATA_TABLE_VERSION);

    //Loop over any remaning old versions of tables and delete
    //them after ensuring data is migrated to the latest versions of the tables
    foreach (string old_table_name in listOfTables) {
      //BOOK_LIBRARY_TABLE5 : Migrate data and drop table
      if(old_table_name == "BOOK_LIBRARY_TABLE5"){
        //copy data to new library table
        queryString = " INSERT INTO "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+
                      "      ( BOOK_LOCATION, BOOK_TITLE, BOOK_AUTHOR, BOOK_COVER_IMAGE_LOCATION, IS_BOOK_COVER_IMAGE_PRESENT, BOOK_PUBLISH_DATE, BOOK_TOTAL_NUMBER_OF_PAGES, BOOK_LAST_READ_PAGE_NUMBER, TAGS, RATINGS, CONTENT_EXTRACTION_LOCATION, creation_date, modification_date)
                        SELECT BOOK_LOCATION, BOOK_TITLE, BOOK_AUTHOR, BOOK_COVER_IMAGE_LOCATION, IS_BOOK_COVER_IMAGE_PRESENT, BOOK_PUBLISH_DATE, BOOK_TOTAL_NUMBER_OF_PAGES, BOOK_LAST_READ_PAGE_NUMBER, TAGS, RATINGS, CONTENT_EXTRACTION_LOCATION, creation_date, modification_date
                        FROM BOOK_LIBRARY_TABLE5";
        executionStatus = bookwormDB.exec (queryString, null, out errmsg);
        if (executionStatus != Sqlite.OK) {
          debug("Executed Query:"+queryString);
          warning ("Error: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
        }else{
          debug("Sucessfully migrated "+bookwormDB.changes().to_string()+" rows from BOOK_LIBRARY_TABLE5 into "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION);
          //copy data to new meta data table
          queryString = " INSERT INTO "+BOOKMETADATA_TABLE_BASE_NAME+BOOKMETADATA_TABLE_VERSION+
                        "      ( id, BOOK_TOC_DATA, BOOKMARKS, CONTENT_DATA_LIST, BOOK_LAST_SCROLL_POSITION, creation_date, modification_date)
                          SELECT id, BOOK_TOC_DATA, BOOKMARKS, CONTENT_DATA_LIST, BOOK_LAST_SCROLL_POSITION, creation_date, modification_date
                          FROM BOOK_LIBRARY_TABLE5";
          executionStatus = bookwormDB.exec (queryString, null, out errmsg);
          if (executionStatus != Sqlite.OK) {
            debug("Executed Query:"+queryString);
            warning ("Error: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
          }else{
            debug("Sucessfully migrated "+bookwormDB.changes().to_string()+" rows from BOOK_LIBRARY_TABLE5 into "+BOOKMETADATA_TABLE_BASE_NAME+BOOKMETADATA_TABLE_VERSION);
            //drop the old table
            queryString = "DROP TABLE IF EXISTS BOOK_LIBRARY_TABLE5";
            executionStatus = bookwormDB.exec (queryString, null, out errmsg);
            if (executionStatus != Sqlite.OK) {
              debug("Executed Query:"+queryString);
              warning ("Error: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
            }else{
              debug("Sucessfully dropped old table LIBRARY_TABLE5");
            }
          }
        }
      }
      //VERSION_TABLE : Drop table
      if(old_table_name == "VERSION_TABLE"){
        //drop the old table
        queryString = "DROP TABLE IF EXISTS VERSION_TABLE";
        executionStatus = bookwormDB.exec (queryString, null, out errmsg);
        if (executionStatus != Sqlite.OK) {
          debug("Executed Query:"+queryString);
          warning ("Error: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
        }else{
          debug("Sucessfully dropped old table VERSION_TABLE");
        }
      }
    }
    //All DB loading operations completed
    debug("All DB loading operations completed sucessfully...");
    return true;
  }

  public static ArrayList<BookwormApp.Book> getBooksFromDB(){
    ArrayList<BookwormApp.Book> listOfBooks = new ArrayList<BookwormApp.Book> ();
    Statement stmt;
    queryString = "SELECT id,
                         BOOK_LOCATION,
                         BOOK_TITLE,
                         BOOK_AUTHOR,
                         BOOK_COVER_IMAGE_LOCATION,
                         IS_BOOK_COVER_IMAGE_PRESENT,
                         BOOK_LAST_READ_PAGE_NUMBER,
                         BOOK_PUBLISH_DATE,
                         TAGS,
                         ANNOTATION_TAGS,
                         RATINGS,
                         CONTENT_EXTRACTION_LOCATION,
                         BOOK_TOTAL_PAGES,
                         creation_date,
                         modification_date
                   FROM "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" ORDER BY modification_date DESC";
    executionStatus = bookwormDB.prepare_v2 (queryString, queryString.length, out stmt);
    if (executionStatus != Sqlite.OK) {
      debug("Error on executing Query:"+queryString);
	 		warning ("Error details: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
	 	}else{
      while (stmt.step () == ROW) {
        BookwormApp.Book aBook = new BookwormApp.Book();
        aBook.setBookId(stmt.column_int(0));
        aBook.setBookLocation(stmt.column_text (1));
        aBook.setBookTitle(stmt.column_text (2));
        aBook.setBookAuthor(stmt.column_text (3));
        aBook.setBookCoverLocation(stmt.column_text (4));
        aBook.setIsBookCoverImagePresent((stmt.column_text (5) == "true") ? true:false);
        aBook.setBookPageNumber(int.parse(stmt.column_text(6)));
        aBook.setBookPublishDate(stmt.column_text (7));
        aBook.setBookTags(stmt.column_text (8));
        aBook.setAnnotationTags(stmt.column_text (9));
        aBook.setBookRating(int.parse(stmt.column_text(10)));
        aBook.setBookExtractionLocation(stmt.column_text (11));
        aBook.setBookTotalPages(int.parse(stmt.column_text (12)));
        aBook.setBookCreationDate(stmt.column_text (13));
        aBook.setBookLastModificationDate(stmt.column_text (14));
        debug("Book details fetched from DB:
                  id="+stmt.column_int(0).to_string()+
                  ",BOOK_LOCATION="+stmt.column_text (1)+
                  ",BOOK_TITLE="+stmt.column_text (2)+
                  ",BOOK_AUTHOR="+stmt.column_text (3)+
                  ",BOOK_COVER_IMAGE_LOCATION="+stmt.column_text (4)+
                  ",IS_BOOK_COVER_IMAGE_PRESENT="+stmt.column_text (5)+
                  ",BOOK_LAST_READ_PAGE_NUMBER="+stmt.column_text (6)+
                  ",BOOK_PUBLISH_DATE="+stmt.column_text (7)+
                  ",TAGS="+stmt.column_text (8)+
                  ",ANNOTATION_TAGS="+stmt.column_text (9)+
                  ",RATINGS="+stmt.column_text (10)+
                  ",CONTENT_EXTRACTION_LOCATION="+stmt.column_text (11)+
                  ",BOOK_TOTAL_PAGES="+stmt.column_text (12)+
                  ",creation_date="+stmt.column_text (13)+
                  ",modification_date="+stmt.column_text (14)
              );
        //add book details to list
        listOfBooks.add(aBook);
        //build the string of book paths in the library
        BookwormApp.Bookworm.pathsOfBooksInLibraryOnLoadStr.append(aBook.getBookLocation());
      }
      stmt.reset ();
    }
    return listOfBooks;
  }

  public static BookwormApp.Book getBookMetaDataFromDB(owned BookwormApp.Book aBook){
    debug("Starting to fetch Meta Data for Book ID="+aBook.getBookId().to_string());
    Statement stmt;
    queryString = "SELECT
                     BOOK_TOC_DATA,
                     BOOKMARKS,
                     CONTENT_DATA_LIST,
                     BOOK_LAST_SCROLL_POSITION,
                     BOOK_ANNOTATIONS
                   FROM "+BOOKMETADATA_TABLE_BASE_NAME+BOOKMETADATA_TABLE_VERSION+
                   " WHERE id = ?";
    executionStatus = bookwormDB.prepare_v2 (queryString, queryString.length, out stmt);
    if (executionStatus != Sqlite.OK) {
      debug("Error on executing Query:"+queryString);
	 		warning ("Error details: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
	 	}
    stmt.bind_int (1, aBook.getBookId());
    while (stmt.step () == ROW) {
      aBook = BookwormApp.Utils.convertStringToTOC(aBook, stmt.column_text (0));
      aBook.setBookmark(-10, stmt.column_text (1));//-10 is a flag to set the bookmark string into the object
      aBook = BookwormApp.Utils.convertStringToContentList(aBook, stmt.column_text (2));
      aBook.setBookScrollPos(int.parse(stmt.column_text(3)));
      aBook.setAnnotationList(BookwormApp.Utils.convertStringToTreeMap(stmt.column_text (4)));
      debug("Book MetaData details fetched from DB:
                id="+aBook.getBookId().to_string()+
                ",BOOK_TOC_DATA="+stmt.column_text (0)+
                ",BOOKMARKS="+stmt.column_text (1)+
                ",CONTENT_DATA_LIST="+stmt.column_text (2)+
                ",BOOK_LAST_SCROLL_POSITION="+stmt.column_text (3)+
                ",BOOK_ANNOTATIONS="+stmt.column_text (4)
           );
    }
    stmt.reset ();
    return aBook;
  }

  public static int addBookToDataBase(BookwormApp.Book aBook){
    Sqlite.Statement stmt;
    int insertedBookID = 0;
    queryString = "INSERT INTO "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+"(
                     BOOK_LOCATION,
                     BOOK_TITLE,
                     BOOK_AUTHOR,
                     BOOK_COVER_IMAGE_LOCATION,
                     IS_BOOK_COVER_IMAGE_PRESENT,
                     CONTENT_EXTRACTION_LOCATION,
                     creation_date,
                     modification_date) "
                + "VALUES (?,?,?,?,?,?, CAST(strftime('%s', 'now') AS INT), CAST(strftime('%s', 'now') AS INT))";
     executionStatus = bookwormDB.prepare_v2 (queryString, queryString.length, out stmt);
     if (executionStatus != Sqlite.OK) {
       debug("Error on executing Query:"+queryString);
       warning ("Error details: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
       return -1;
     }
     stmt.bind_text (1, aBook.getBookLocation());
     stmt.bind_text (2, aBook.getBookTitle());
     stmt.bind_text (3, aBook.getBookAuthor());
     stmt.bind_text (4, aBook.getBookCoverLocation());
     stmt.bind_text (5, aBook.getIsBookCoverImagePresent().to_string());
     stmt.bind_text (6, aBook.getBookExtractionLocation());

     stmt.step ();
     stmt.reset ();
     //fetch the id of the book just inserted into the DB
     queryString = "SELECT id FROM " + BOOKWORM_TABLE_BASE_NAME + BOOKWORM_TABLE_VERSION +
                   " WHERE BOOK_LOCATION = ?";

     executionStatus = bookwormDB.prepare_v2 (queryString, queryString.length, out stmt);
     if (executionStatus != Sqlite.OK) {
       debug("Error on executing Query:"+queryString);
       warning ("Error details: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
     }
     stmt.bind_text (1, aBook.getBookLocation());
     while (stmt.step () == ROW) {
       insertedBookID = stmt.column_int(0);
     }
     stmt.reset ();
     debug("Added details to Database for book:"+aBook.getBookLocation());
     return insertedBookID;
  }

  public static bool removeBookFromDB(BookwormApp.Book aBook){
    Sqlite.Statement stmt;
    //delete book from library table
    queryString = "DELETE FROM "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" WHERE id = ?";
    executionStatus = bookwormDB.prepare_v2 (queryString, queryString.length, out stmt);
    if (executionStatus != Sqlite.OK) {
      debug("Error on executing Query:"+queryString);
      warning ("Error details: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
      return false;
    }else{
      stmt.bind_int (1, aBook.getBookId());
      stmt.step ();
      stmt.reset ();
      debug("Removed this book from library table:"+aBook.getBookTitle()+"["+aBook.getBookId().to_string()+"]");

      //delete book meta data from meta data table
      queryString = "DELETE FROM "+BOOKMETADATA_TABLE_BASE_NAME+BOOKMETADATA_TABLE_VERSION+" WHERE id = ?";
      executionStatus = bookwormDB.prepare_v2 (queryString, queryString.length, out stmt);
      if (executionStatus != Sqlite.OK) {
        debug("Error on executing Query:"+queryString);
        warning ("Error details: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
        return false;
      }else{
        stmt.bind_int (1, aBook.getBookId());
        stmt.step ();
        stmt.reset ();
        debug("Removed this book from meta data table:"+aBook.getBookTitle()+"["+aBook.getBookId().to_string()+"]");
      }
    }

    return true;
  }

  public static bool updateBookToDataBase(BookwormApp.Book aBook){
    Sqlite.Statement stmt;
    queryString = "UPDATE "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" SET
                      BOOK_LAST_READ_PAGE_NUMBER = ?,
                      BOOK_TITLE = ?,
                      BOOK_AUTHOR = ?,
                      BOOK_COVER_IMAGE_LOCATION = ?,
                      IS_BOOK_COVER_IMAGE_PRESENT = ?,
                      TAGS = ?,
                      ANNOTATION_TAGS = ?,
                      RATINGS = ?,
                      CONTENT_EXTRACTION_LOCATION = ?,
                      BOOK_TOTAL_PAGES = ?,
                      modification_date = CAST(? AS INT)
                   WHERE BOOK_LOCATION = ? ";
     executionStatus = bookwormDB.prepare_v2 (queryString, queryString.length, out stmt);
     if (executionStatus != Sqlite.OK) {
       debug("Error on executing Query:"+queryString);
       warning ("Error details: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
       return false;
     }
     stmt.bind_text (1, aBook.getBookPageNumber().to_string());
     stmt.bind_text (2, aBook.getBookTitle());
     stmt.bind_text (3, aBook.getBookAuthor());
     stmt.bind_text (4, aBook.getBookCoverLocation());
     stmt.bind_text (5, aBook.getIsBookCoverImagePresent().to_string());
     stmt.bind_text (6, aBook.getBookTags());
     stmt.bind_text (7, aBook.getAnnotationTags());
     stmt.bind_text (8, aBook.getBookRating().to_string());
     stmt.bind_text (9, aBook.getBookExtractionLocation());
     stmt.bind_text (10, aBook.getBookTotalPages().to_string());
     stmt.bind_text (11, aBook.getBookLastModificationDate());
     stmt.bind_text (12, aBook.getBookLocation());
     stmt.step ();
     stmt.reset ();
     debug("Updated library details to "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" for book:"+aBook.getBookTitle()+"["+aBook.getBookId().to_string()+"]");

     //Attempt to insert book meta data
     queryString = "INSERT OR IGNORE INTO "+BOOKMETADATA_TABLE_BASE_NAME+BOOKMETADATA_TABLE_VERSION+" (
                       BOOK_TOC_DATA,
                       BOOKMARKS,
                       CONTENT_DATA_LIST,
                       BOOK_LAST_SCROLL_POSITION,
                       BOOK_ANNOTATIONS,
                       modification_date,
                       id) "
                  + "VALUES (?,?,?,?,?,CAST(strftime('%s', 'now') AS INT),?);";
     executionStatus = bookwormDB.prepare_v2 (queryString, queryString.length, out stmt);
     if (executionStatus != Sqlite.OK) {
       debug("Error on executing Query:"+queryString);
       warning ("Error details: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
       return false;
     }
     stmt.bind_text (1, BookwormApp.Utils.convertTOCToString(aBook));
     stmt.bind_text (2, aBook.getBookmark());
     stmt.bind_text (3, BookwormApp.Utils.convertContentListToString(aBook));
     stmt.bind_text (4, aBook.getBookScrollPos().to_string());
     stmt.bind_text (5, BookwormApp.Utils.convertTreeMapToString(aBook.getAnnotationList()));
     stmt.bind_int  (6, aBook.getBookId());
     stmt.step ();
     stmt.reset ();
     if(bookwormDB.changes() == 0){
       //Book already present, update the meta data
       queryString = "UPDATE "+BOOKMETADATA_TABLE_BASE_NAME+BOOKMETADATA_TABLE_VERSION+" SET
                          BOOK_TOC_DATA = ?,
                          BOOKMARKS = ?,
                          CONTENT_DATA_LIST = ?,
                          BOOK_LAST_SCROLL_POSITION = ?,
                          BOOK_ANNOTATIONS = ?,
                          modification_date = CAST(strftime('%s', 'now') AS INT)
                        WHERE id = ? ";
       executionStatus = bookwormDB.prepare_v2 (queryString, queryString.length, out stmt);
       if (executionStatus != Sqlite.OK) {
         debug("Error on executing Query:"+queryString);
         warning ("Error details: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
         return false;
       }
       stmt.bind_text (1, BookwormApp.Utils.convertTOCToString(aBook));
       stmt.bind_text (2, aBook.getBookmark());
       stmt.bind_text (3, BookwormApp.Utils.convertContentListToString(aBook));
       stmt.bind_text (4, aBook.getBookScrollPos().to_string());
       stmt.bind_text (5, BookwormApp.Utils.convertTreeMapToString(aBook.getAnnotationList()));
       stmt.bind_int  (6, aBook.getBookId());
       stmt.step ();
       stmt.reset ();
       debug("Updated book meta data details to "+BOOKMETADATA_TABLE_BASE_NAME+BOOKMETADATA_TABLE_VERSION+" for book:"+aBook.getBookTitle()+"["+aBook.getBookId().to_string()+"]");
     }else{
       debug("Inserted book meta data details to "+BOOKMETADATA_TABLE_BASE_NAME+BOOKMETADATA_TABLE_VERSION+" for book:"+aBook.getBookTitle()+"["+aBook.getBookId().to_string()+"]");
     }
     return true;
  }

  public static ArrayList<string> getBookIDListFromDB(){
    ArrayList<string> bookIDList = new ArrayList<string> ();
    Statement stmt;
    queryString = "SELECT id,BOOK_LOCATION FROM "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" ORDER BY id DESC";
    executionStatus = bookwormDB.prepare_v2 (queryString, queryString.length, out stmt);
    if (executionStatus != Sqlite.OK) {
      debug("Error on executing Query:"+queryString);
      warning ("Error details: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
	 	}
    while (stmt.step () == ROW) {
      bookIDList.add(stmt.column_int(0).to_string()+"::"+stmt.column_text (1));
    }
    stmt.reset ();
    return bookIDList;
  }

}
