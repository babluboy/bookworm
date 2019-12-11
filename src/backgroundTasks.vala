/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and performs background
* related tasks like discovering books, cleaning cached data, etc.
* This code does not require a GUI/Display
* This code should be called from a sheduled job as "bookworm --discover"
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
public class BookwormApp.BackgroundTasks {
    public static ArrayList<string> listOfBooks;
    public static BookwormApp.Settings settings;

    public static void performTasks () {
        initialization ();
        //Add any new books from the watched folders
        discoverBooks ();
        //refresh list of books in DB due to new books being added
        listOfBooks = BookwormApp.DB.getBookIDListFromDB ();
        //Remove cahched data and cover thumbs which are no longer used
        cleanBookCacheContent ();
        cleanBookCoverImages ();
    }

    public static void initialization () {
        settings = BookwormApp.Settings.get_instance ();
        //check if the database exists otherwise create database and required tables
        BookwormApp.DB.initializeBookWormDB (BookwormApp.Bookworm.bookworm_config_path);
        listOfBooks = BookwormApp.DB.getBookIDListFromDB ();
    }

    public static void discoverBooks () {
        print ("\nStarted process for discovery of books....");
        ArrayList<string> scanDirList = new ArrayList<string> ();
        //find the folders to scan from the settings
        if (settings != null && settings.list_of_scan_dirs != null && settings.list_of_scan_dirs.length > 1) {
            debug (settings.list_of_scan_dirs);
            string[] scanDirArray = settings.list_of_scan_dirs.split ("~~");
            foreach (string token in scanDirArray) {
                scanDirList.add (token);
            }

            if (scanDirList.size > 0) {
                //create the find command
                StringBuilder findCmd = new StringBuilder ("find ");
                foreach (string scanDir in scanDirList) {
                    if (scanDir != null && scanDir.length > 1) {
                        findCmd.append ("\"").append (scanDir).append ("\"").append (" ");
                    }
                }
                findCmd.append ("! -readable -prune -o -type f \\( -iname \\*.mobi -o -iname \\*.pdf -o -iname \\*.epub -o -iname \\*.cbr -o -iname \\*.cbz \\) -print");
                string findCmdOutput = BookwormApp.Utils.execute_sync_command (findCmd.str);
                if (findCmdOutput.contains ("\n")) {
                    string[] findCmdOutputResults = findCmdOutput.strip ().split ("\n",-1);
                    foreach (string findResult in findCmdOutputResults) {
                        bool noMatchFound = true;
                        foreach (string book in listOfBooks) {
                            if (book.contains (findResult)) {
                                noMatchFound = false;
                                break;
                            }
                        }
                        if (noMatchFound) {
                            print ("\nAttempting to add book located at:" + findResult);
                            BookwormApp.Book aBook = new BookwormApp.Book ();
                            aBook.setBookLocation (findResult);
                            File eBookFile = File.new_for_path (findResult);
                            if (eBookFile.query_exists () && eBookFile.query_file_type (0) != FileType.DIRECTORY) {
                                int bookID = BookwormApp.DB.addBookToDataBase (aBook);
                                aBook.setBookId (bookID);
                                aBook.setBookLastModificationDate ((new DateTime.now_utc ().to_unix ()).to_string ());
                                aBook.setWasBookOpened (true);
                                //parse eBook to populate cache and book meta data
                                aBook = BookwormApp.Bookworm.genericParser (aBook);
                                if (!aBook.getIsBookParsed ()) {
                                    BookwormApp.DB.removeBookFromDB (aBook);
                                } else {
                                    BookwormApp.DB.updateBookToDataBase (aBook);
                                    print ("\nSuccessfully added book located at:" + findResult);
                                }
                            }
                        }
                    }
                }
                print ("\nCompleted process for discovery of books....\n");
            }
        }
    }

    public static void cleanBookCacheContent () {
        print ("\nStarting to delete un-necessary cache data...");
        //list the folders in the cache
        string cacheFolders = BookwormApp.Utils.execute_sync_command ("ls -1 " + BookwormApp.Bookworm.bookworm_config_path + "/books/");
        cacheFolders = cacheFolders.replace ("\r", "^^^").replace ("\n", "^^^");
        string[] cacheFolderList = cacheFolders.split ("^^^");
        //loop through each folder name
        bool folderMatched = false;
        foreach (string cacheFolder in cacheFolderList) {
            folderMatched = false;
            cacheFolder = cacheFolder.strip ();
            if (cacheFolder == null || cacheFolder.length < 1) {
                folderMatched = true;
            }
            foreach (string bookData in listOfBooks) {
                if (cacheFolder != null && cacheFolder.length > 0) {
                    //check if the folder is part of a book in the library
                    if ((bookData.split ("::")[1]).index_of (cacheFolder) != -1) {
                        folderMatched = true;
                        break;
                    }
                }
            }
            if (!folderMatched) {
                //delete the folder and content if it is not a part of any book in the library
                BookwormApp.Utils.execute_sync_command ("rm -Rf \"" + BookwormApp.Bookworm.bookworm_config_path + "/books/" + cacheFolder + "\"");
                print ("\nCache Folder deleted:" + cacheFolder);
            }
        }
    }

    public static void cleanBookCoverImages () {
        print ("\nStarting to delete un-necessary cover image data...");
        //list the cover images in the cache
        string cacheImages = BookwormApp.Utils.execute_sync_command ("ls -1 " + BookwormApp.Bookworm.bookworm_config_path + "/covers/");
        cacheImages = cacheImages.replace ("\r", "^^^").replace ("\n", "^^^");
        string[] cacheImageList = cacheImages.split ("^^^");
        //loop through each cover image in cache
        bool imageMatched = false;
        foreach (string cacheImage in cacheImageList) {
            imageMatched = false;
            cacheImage = cacheImage.strip ();
            if (cacheImage == null || cacheImage.length < 1) {
                imageMatched = true;
            }
            foreach (string bookData in listOfBooks) {
                if (cacheImage != null && cacheImage.length > 0) {
                    //check if the folder is part of a book in the library
                    if (cacheImage.index_of ((bookData.split ("::")[0])) != -1) {
                        imageMatched = true;
                        break;
                    }
                }
            }
            if (!imageMatched) {
                //delete the folder and content if it is not a part of any book in the library
                BookwormApp.Utils.execute_sync_command ("rm -f \"" + BookwormApp.Bookworm.bookworm_config_path + "/covers/" + cacheImage + "\"");
                print ("\nCache Image deleted:" + cacheImage);
            }
        }
    }
}
