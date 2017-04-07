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
  public static const string BOOKWORM_TABLE_VERSION = "1"; //Only integers allowed
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
                               + "BOOKMARKS TEXT NOT NULL DEFAULT '', "
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
       //This block is for copying initial version to current version
       if("" == library_table_version){
         string sync_to_latest_table = "INSERT INTO "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+" (
                                             id,
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
                                             modification_date
                                        )
                                        SELECT
                                              id,
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
                                              modification_date
                                        FROM BOOK_LIBRARY_TABLE";
         int syncTableStatus = bookwormDB.prepare_v2 (sync_to_latest_table, sync_to_latest_table.length, out stmt);
         if (syncTableStatus != Sqlite.OK) {
           debug("Executed Query:"+sync_to_latest_table);
           warning ("Error: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
           return false;
         }
         stmt.step ();
         stmt.reset ();
       }
       debug("Synced data to latest table version["+BOOKWORM_TABLE_VERSION+"] to Database");
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
                                       BOOK_COVER_IMAGE_LOCATION,
                                       IS_BOOK_COVER_IMAGE_PRESENT,
                                       BOOK_LAST_READ_PAGE_NUMBER,
                                       BOOK_PUBLISH_DATE,
                                       BOOKMARKS,
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
      aBook.setBookCoverLocation(stmt.column_text (3));
      aBook.setIsBookCoverImagePresent((stmt.column_text (4) == "true") ? true:false);
      aBook.setBookPageNumber(int.parse(stmt.column_text(5)));
      aBook.setBookPublishDate(stmt.column_text (6));
      aBook.setBookmark(-10, stmt.column_text (7));//-10 is a flag to set the bookmark string into the object
      aBook.setBookCreationDate(stmt.column_text (8));
      aBook.setBookLastModificationDate(stmt.column_text (9));
      debug("Book details fetched from DB:
                id="+stmt.column_int(0).to_string()+
                ",BOOK_LOCATION="+stmt.column_text (1)+
                ",BOOK_TITLE="+stmt.column_text (2)+
                ",BOOK_COVER_IMAGE_LOCATION="+stmt.column_text (3)+
                ",IS_BOOK_COVER_IMAGE_PRESENT="+stmt.column_text (4)+
                ",BOOK_LAST_READ_PAGE_NUMBER="+stmt.column_text (5)+
                ",BOOK_PUBLISH_DATE="+stmt.column_text (6)+
                ",BOOKMARKS="+stmt.column_text (7)+
                ",creation_date="+stmt.column_text (8)+
                ",modification_date="+stmt.column_text (9)
            );
      //add book details to list
      listOfBooks.add(aBook);
    }
    stmt.reset ();
    return listOfBooks;
  }

  public static bool addBookToDataBase(BookwormApp.Book aBook){
    Sqlite.Statement stmt;
    string insert_data_to_database = "INSERT INTO "+BOOKWORM_TABLE_BASE_NAME+BOOKWORM_TABLE_VERSION+"(
                                                             BOOK_LOCATION,
                                                             BOOK_TITLE,
                                                             BOOK_COVER_IMAGE_LOCATION,
                                                             IS_BOOK_COVER_IMAGE_PRESENT,
                                                             creation_date,
                                                             modification_date) "
                                  + "VALUES (?,?,?,?, CAST(strftime('%s', 'now') AS INT), CAST(strftime('%s', 'now') AS INT))";
     int statusBookToDB = bookwormDB.prepare_v2 (insert_data_to_database, insert_data_to_database.length, out stmt);
     if (statusBookToDB != Sqlite.OK) {
       debug("Executed Query:"+insert_data_to_database);
       warning ("Error: %d: %s\n", bookwormDB.errcode (), bookwormDB.errmsg ());
       return false;
     }
     stmt.bind_text (1, aBook.getBookLocation());
     stmt.bind_text (2, aBook.getBookTitle());
     stmt.bind_text (3, aBook.getBookCoverLocation());
     stmt.bind_text (4, aBook.getIsBookCoverImagePresent().to_string());

     stmt.step ();
     stmt.reset ();
     debug("Added details to Database for book:"+aBook.getBookLocation());
     return true;
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
                                      BOOK_COVER_IMAGE_LOCATION = ?,
                                      IS_BOOK_COVER_IMAGE_PRESENT = ?,
                                      BOOKMARKS = ?,
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
     stmt.bind_text (3, aBook.getBookCoverLocation());
     stmt.bind_text (4, aBook.getIsBookCoverImagePresent().to_string());
     stmt.bind_text (5, aBook.getBookmark());
     stmt.bind_text (6, aBook.getBookLastModificationDate());
     stmt.bind_text (7, aBook.getBookLocation());

     stmt.step ();
     stmt.reset ();
     debug("Updated details to Database for book:"+aBook.getBookLocation());
     return true;
  }


}
