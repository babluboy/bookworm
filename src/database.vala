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
  public static const string BOOKWORM_TABLE_VERSION = "5"; //Only integers allowed
  private static Sqlite.Database bookwormDB;
  private static string errmsg;

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
    } else{
        debug ("Sucessfully checked/created DB for Bookworm.....");
    }

    debug ("Creating latest version for Library table if it does not exists");
    string create_library_table = "CREATE TABLE IF NOT EXISTS "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" ("
                               + "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                               + "BOOK_LOCATION TEXT NOT NULL DEFAULT '', "
															 + "BOOK_TITLE TEXT NOT NULL DEFAULT '', "
                               + "BOOK_AUTHOR TEXT NOT NULL DEFAULT '', "
                               + "BOOK_COVER_IMAGE_LOCATION TEXT NOT NULL DEFAULT '', "
															 + "IS_BOOK_COVER_IMAGE_PRESENT TEXT NOT NULL DEFAULT '', "
                               + "BOOK_PUBLISH_DATE TEXT NOT NULL DEFAULT '', "
															 + "BOOK_TOC_DATA TEXT NOT NULL DEFAULT '', "
															 + "BOOK_TOTAL_NUMBER_OF_PAGES TEXT NOT NULL DEFAULT '', "
															 + "BOOK_LAST_READ_PAGE_NUMBER TEXT NOT NULL DEFAULT '', "
                               + "BOOKMARKS TEXT NOT NULL DEFAULT '', " //Added in table v1
                               + "TAGS TEXT NOT NULL DEFAULT '', " //Added in table v3
                               + "RATINGS TEXT NOT NULL DEFAULT '', " //Added in table v3
                               + "CONTENT_EXTRACTION_LOCATION TEXT NOT NULL DEFAULT '', " //Added in table v4
                               + "CONTENT_DATA_LIST TEXT NOT NULL DEFAULT '', " //Added in table v4
                               + "BOOK_LAST_SCROLL_POSITION TEXT NOT NULL DEFAULT '', " //Added in table v5
                               + "creation_date INTEGER,"
                               + "modification_date INTEGER)";
		int librarytableCreateStatus = bookwormDB.exec (create_library_table, null, out errmsg);
	 	if (librarytableCreateStatus != Sqlite.OK) {
      debug("Executed Query:"+create_library_table);
	 		warning ("Error in creating table[BOOK_LIBRARY_TABLE]: %s\n", errmsg);
      return false;
	 	}

    debug("Checking/creating bookworm VERSION_TABLE...");
    string create_version_table = "CREATE TABLE IF NOT EXISTS VERSION_TABLE ("
                               + "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                               + "BOOKWORM_APP_VERSION TEXT NOT NULL DEFAULT '', "
															 + "BOOKWORM_LIBRARY_TABLE_VERSION TEXT NOT NULL DEFAULT '', "
                               + "BOOKWORM_TABLE_LIST TEXT NOT NULL DEFAULT '', "
                               + "creation_date INTEGER,"
                               + "modification_date INTEGER)";
		int versiontableCreateStatus = bookwormDB.exec (create_version_table, null, out errmsg);
	 	if (versiontableCreateStatus != Sqlite.OK) {
      debug("Running SQL Query:"+create_version_table);
	 		warning ("Error in creating table[BOOK_LIBRARY_TABLE]: %s\n", errmsg);
      return false;
	 	}else{
      debug("Sucessfully checked/created Bookworm VERSION_TABLE...");
    }

    debug("Check VERSION table to see if the current DB version is the latest");
    string fetchVersionQuery = "SELECT id,
                                       BOOKWORM_APP_VERSION,
                                       BOOKWORM_LIBRARY_TABLE_VERSION,
                                       BOOKWORM_TABLE_LIST
                                       FROM VERSION_TABLE
                                WHERE id = (SELECT MAX(id) FROM VERSION_TABLE)";
    int getVersionStatus = bookwormDB.prepare_v2 (fetchVersionQuery, -1, out stmt);
    assert (getVersionStatus == Sqlite.OK);
    if (getVersionStatus != Sqlite.OK) {
      debug("Running SQL Query:"+fetchVersionQuery);
	 		warning ("Error in checking table version: %s\n", errmsg);
      return false;
	 	}
    string app_version = "";
    string library_table_version = "";
    string table_list = "";
    while (stmt.step () == ROW) {
      app_version = stmt.column_text (1);
      library_table_version = stmt.column_text (2);
      table_list = stmt.column_text (3);
    }
    stmt.reset ();
    debug("Latest version of BOOKWORM_LIBRARY_TABLE_VERSION is ["+BOOKWORM_TABLE_VERSION+"] and version fetched from VERSION_TABLE is ["+library_table_version+"]");

    if(BOOKWORM_TABLE_VERSION != library_table_version){
      //update the version table with the latest version
      string updateLatestVersion = "INSERT INTO VERSION_TABLE(
                                                               BOOKWORM_APP_VERSION,
                                                               BOOKWORM_LIBRARY_TABLE_VERSION,
                                                               BOOKWORM_TABLE_LIST,
                                                               creation_date,
                                                               modification_date) "
                                  + "VALUES (?,?,?, CAST(strftime('%s', 'now') AS INT), CAST(strftime('%s', 'now') AS INT))";
       int versionUpdateStatus = bookwormDB.prepare_v2 (updateLatestVersion, updateLatestVersion.length, out stmt);
       if (versionUpdateStatus != Sqlite.OK) {
         debug("Executed Query:"+updateLatestVersion);
         warning ("Error: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
         return false;
       }
       stmt.bind_text (1, BookwormApp.Constants.bookworm_version);
       stmt.bind_text (2, BOOKWORM_TABLE_VERSION);
       stmt.bind_text (3, "VERSION_TABLE|"+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION);
       stmt.step ();
       stmt.reset ();
       debug("Updated latest database version info into Database");

       //This block is for copying any initial version to current version
       string sync_to_latest_table = "";
       string initial_list_of_columns = "id,
                                         BOOK_LOCATION,
                                         BOOK_TITLE,
                                         BOOK_AUTHOR,
                                         BOOK_COVER_IMAGE_LOCATION,
                                         IS_BOOK_COVER_IMAGE_PRESENT,
                                         BOOK_PUBLISH_DATE,
                                         BOOK_TOC_DATA,
                                         BOOK_TOTAL_NUMBER_OF_PAGES,
                                         BOOK_LAST_READ_PAGE_NUMBER,
                                         creation_date,
                                         modification_date";
       if("" == library_table_version){
         sync_to_latest_table = "INSERT INTO "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" ("
           + initial_list_of_columns + ")" +
           "SELECT "
           + initial_list_of_columns +
           " FROM BOOK_LIBRARY_TABLE";
        } else if ("1" == library_table_version) {
          sync_to_latest_table = "INSERT INTO "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" ("
            + initial_list_of_columns + ",BOOKMARKS)" +
            "SELECT "
            + initial_list_of_columns + ",BOOKMARKS" +
            " FROM BOOK_LIBRARY_TABLE1";
        } else if("3" == library_table_version) {
          sync_to_latest_table = "INSERT INTO "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" ("
            + initial_list_of_columns + ",BOOKMARKS,TAGS,RATINGS)" +
            "SELECT "
            + initial_list_of_columns + ",BOOKMARKS,TAGS,RATINGS" +
            " FROM BOOK_LIBRARY_TABLE3";
        } else if("4" == library_table_version) {
          sync_to_latest_table = "INSERT INTO "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" ("
            + initial_list_of_columns + ",BOOKMARKS,TAGS,RATINGS,CONTENT_EXTRACTION_LOCATION,CONTENT_DATA_LIST)" +
            "SELECT "
            + initial_list_of_columns + ",BOOKMARKS,TAGS,RATINGS,CONTENT_EXTRACTION_LOCATION,CONTENT_DATA_LIST" +
            " FROM BOOK_LIBRARY_TABLE4";
        }

       int syncTableStatus = bookwormDB.prepare_v2 (sync_to_latest_table, sync_to_latest_table.length, out stmt);
       if (syncTableStatus != Sqlite.OK) {
         debug("Executed Query:"+sync_to_latest_table);
         warning ("Error: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
       } else {
         stmt.step ();
         stmt.reset ();
         debug("Synced data to latest table version["+BOOKWORM_TABLE_VERSION+"] to Database");

         //drop older tables if they exist
         Statement stmt_drop;
         string drop_table_query = "";
         for(int tableVersion=0; tableVersion < BOOKWORM_TABLE_VERSION.to_int(); tableVersion++){
           if(tableVersion == 0){
             drop_table_query = "DROP TABLE IF EXISTS BOOK_LIBRARY_TABLE";
           }else{
             drop_table_query = "DROP TABLE IF EXISTS BOOK_LIBRARY_TABLE"+tableVersion.to_string();
           }
           int statusDropTable = bookwormDB.prepare_v2 (drop_table_query, drop_table_query.length, out stmt_drop);
           if (statusDropTable != Sqlite.OK) {
             debug("Executed Query:"+drop_table_query);
             warning ("Error: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
           }
           stmt_drop.step ();
           stmt_drop.reset ();
           debug("Old table ["+tableVersion.to_string()+"] dropped from Bookworm Database");
         }
       }
    }

    //All DB loading operations completed
    return true;
  }

  public static ArrayList<BookwormApp.Book> getBooksFromDB(){
    ArrayList<BookwormApp.Book> listOfBooks = new ArrayList<BookwormApp.Book> ();
    Statement stmt;
    string fetchLibraryQuery = "SELECT id,
                                       BOOK_LOCATION,
                                       BOOK_TITLE,
                                       BOOK_AUTHOR,
                                       BOOK_COVER_IMAGE_LOCATION,
                                       IS_BOOK_COVER_IMAGE_PRESENT,
                                       BOOK_LAST_READ_PAGE_NUMBER,
                                       BOOK_PUBLISH_DATE,
                                       BOOKMARKS,
                                       TAGS,
                                       RATINGS,
                                       CONTENT_EXTRACTION_LOCATION,
                                       CONTENT_DATA_LIST,
                                       BOOK_TOC_DATA,
                                       BOOK_LAST_SCROLL_POSITION,
                                       creation_date,
                                       modification_date
                                FROM "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" ORDER BY modification_date DESC";
    int getAllBookStatus = bookwormDB.prepare_v2 (fetchLibraryQuery, -1, out stmt);
    assert (getAllBookStatus == Sqlite.OK);
    if (getAllBookStatus != Sqlite.OK) {
      debug("Executed Query:"+fetchLibraryQuery);
	 		warning ("Error in fetching book data from database: %s\n", errmsg);
	 	}
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
      aBook.setBookmark(-10, stmt.column_text (8));//-10 is a flag to set the bookmark string into the object
      aBook.setBookTags(stmt.column_text (9));
      aBook.setBookRating(int.parse(stmt.column_text(10)));
      aBook.setBookExtractionLocation(stmt.column_text (11));
      aBook = BookwormApp.Utils.convertStringToContentList(aBook, stmt.column_text (12));
      aBook = BookwormApp.Utils.convertStringToTOC(aBook, stmt.column_text (13));
      aBook.setBookScrollPos(int.parse(stmt.column_text(14)));
      aBook.setBookCreationDate(stmt.column_text (15));
      aBook.setBookLastModificationDate(stmt.column_text (16));
      debug("Book details fetched from DB:
                id="+stmt.column_int(0).to_string()+
                ",BOOK_LOCATION="+stmt.column_text (1)+
                ",BOOK_TITLE="+stmt.column_text (2)+
                ",BOOK_AUTHOR="+stmt.column_text (3)+
                ",BOOK_COVER_IMAGE_LOCATION="+stmt.column_text (4)+
                ",IS_BOOK_COVER_IMAGE_PRESENT="+stmt.column_text (5)+
                ",BOOK_LAST_READ_PAGE_NUMBER="+stmt.column_text (6)+
                ",BOOK_PUBLISH_DATE="+stmt.column_text (7)+
                ",BOOKMARKS="+stmt.column_text (8)+
                ",TAGS="+stmt.column_text (9)+
                ",RATINGS="+stmt.column_text (10)+
                ",CONTENT_EXTRACTION_LOCATION="+stmt.column_text (11)+
                ",CONTENT_DATA_LIST="+stmt.column_text (12)+
                ",BOOK_TOC_DATA="+stmt.column_text (13)+
                ",BOOK_LAST_SCROLL_POSITION="+stmt.column_text (14)+
                ",creation_date="+stmt.column_text (15)+
                ",modification_date="+stmt.column_text (16)
            );
      //add book details to list
      listOfBooks.add(aBook);
      //build the string of book paths in the library
      BookwormApp.Bookworm.pathsOfBooksInLibraryOnLoadStr.append(aBook.getBookLocation());
    }
    stmt.reset ();
    return listOfBooks;
  }

  public static int addBookToDataBase(BookwormApp.Book aBook){
    Sqlite.Statement stmt;
    int insertedBookID = 0;
    string insert_data_to_database = "INSERT INTO "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+"(
                                                             BOOK_LOCATION,
                                                             BOOK_TITLE,
                                                             BOOK_AUTHOR,
                                                             BOOK_COVER_IMAGE_LOCATION,
                                                             IS_BOOK_COVER_IMAGE_PRESENT,
                                                             CONTENT_EXTRACTION_LOCATION,
                                                             CONTENT_DATA_LIST,
                                                             creation_date,
                                                             modification_date) "
                                  + "VALUES (?,?,?,?,?,?,?, CAST(strftime('%s', 'now') AS INT), CAST(strftime('%s', 'now') AS INT))";
     int statusBookToDB = bookwormDB.prepare_v2 (insert_data_to_database, insert_data_to_database.length, out stmt);
     if (statusBookToDB != Sqlite.OK) {
       debug("Executed Query:"+insert_data_to_database);
       warning ("Error: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
       return -1;
     }
     stmt.bind_text (1, aBook.getBookLocation());
     stmt.bind_text (2, aBook.getBookTitle());
     stmt.bind_text (3, aBook.getBookAuthor());
     stmt.bind_text (4, aBook.getBookCoverLocation());
     stmt.bind_text (5, aBook.getIsBookCoverImagePresent().to_string());
     stmt.bind_text (6, aBook.getBookExtractionLocation());
     stmt.bind_text (7, BookwormApp.Utils.convertContentListToString(aBook));

     stmt.step ();
     stmt.reset ();
     //fetch the id of the book just inserted into the DB
     string fetchInsertedBookID = "SELECT id FROM " + BOOKWORM_TABLE_BASE_NAME + BOOKWORM_TABLE_VERSION +
                                  " WHERE BOOK_LOCATION = ?";

     int statusBookInsertedID = bookwormDB.prepare_v2 (fetchInsertedBookID, fetchInsertedBookID.length, out stmt);
     if (statusBookInsertedID != Sqlite.OK) {
       debug("Executed Query:"+fetchInsertedBookID);
       warning ("Error: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
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
    string delete_book_from_database = "DELETE FROM "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" WHERE BOOK_LOCATION = ?";
    int statusDeleteBookFromDB = bookwormDB.prepare_v2 (delete_book_from_database, delete_book_from_database.length, out stmt);
    if (statusDeleteBookFromDB != Sqlite.OK) {
      debug("Executed Query:"+delete_book_from_database);
      warning ("Error: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
      return false;
    }
    stmt.bind_text (1, aBook.getBookLocation());
    stmt.step ();
    stmt.reset ();
    debug("Removed this book from Database:"+aBook.getBookLocation());
    return true;
  }

  public static bool updateBookToDataBase(BookwormApp.Book aBook){
    Sqlite.Statement stmt;
    string update_book_to_database = "UPDATE "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" SET
                                      BOOK_LAST_READ_PAGE_NUMBER = ?,
                                      BOOK_TITLE = ?,
                                      BOOK_AUTHOR = ?,
                                      BOOK_COVER_IMAGE_LOCATION = ?,
                                      IS_BOOK_COVER_IMAGE_PRESENT = ?,
                                      BOOKMARKS = ?,
                                      TAGS = ?,
                                      RATINGS = ?,
                                      CONTENT_EXTRACTION_LOCATION = ?,
                                      CONTENT_DATA_LIST = ?,
                                      BOOK_TOC_DATA = ?,
                                      BOOK_LAST_SCROLL_POSITION = ?,
                                      modification_date = CAST(? AS INT)
                                      WHERE BOOK_LOCATION = ? ";
     int statusBookToDB = bookwormDB.prepare_v2 (update_book_to_database, update_book_to_database.length, out stmt);
     if (statusBookToDB != Sqlite.OK) {
       debug("Executed Query:"+update_book_to_database);
       warning ("Error: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
       return false;
     }
     stmt.bind_text (1, aBook.getBookPageNumber().to_string());
     stmt.bind_text (2, aBook.getBookTitle());
     stmt.bind_text (3, aBook.getBookAuthor());
     stmt.bind_text (4, aBook.getBookCoverLocation());
     stmt.bind_text (5, aBook.getIsBookCoverImagePresent().to_string());
     stmt.bind_text (6, aBook.getBookmark());
     stmt.bind_text (7, aBook.getBookTags());
     stmt.bind_text (8, aBook.getBookRating().to_string());
     stmt.bind_text (9, aBook.getBookExtractionLocation());
     stmt.bind_text (10, BookwormApp.Utils.convertContentListToString(aBook));
     stmt.bind_text (11, BookwormApp.Utils.convertTOCToString(aBook));
     stmt.bind_text (12, aBook.getBookScrollPos().to_string());
     stmt.bind_text (13, aBook.getBookLastModificationDate());
     stmt.bind_text (14, aBook.getBookLocation());

     stmt.step ();
     stmt.reset ();
     debug("Updated details to Database for book:"+aBook.getBookLocation());
     return true;
  }

  public static ArrayList<string> getBookIDListFromDB(){
    ArrayList<string> bookIDList = new ArrayList<string> ();
    Statement stmt;
    string fetchBookIDListQuery = "SELECT id,BOOK_LOCATION FROM "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" ORDER BY id DESC";
    int getIDListStatus = bookwormDB.prepare_v2 (fetchBookIDListQuery, -1, out stmt);
    assert (getIDListStatus == Sqlite.OK);
    if (getIDListStatus != Sqlite.OK) {
      debug("Executed Query:"+fetchBookIDListQuery);
	 		warning ("Error in fetching book ID List from database: %s\n", errmsg);
	 	}
    while (stmt.step () == ROW) {
      bookIDList.add(stmt.column_int(0).to_string()+"::"+stmt.column_text (1));
    }
    stmt.reset ();
    return bookIDList;
  }

}
