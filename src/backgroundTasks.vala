/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and performs background
* related tasks like discovering books. These tasks does not require a GUI
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
  public static BookwormApp.Settings settings;
  //public static string bookworm_config_path = GLib.Environment.get_user_config_dir ()+"/bookworm";
  public static void performTasks(){
    discoverBooks();
  }

  public static void discoverBooks(){
    print("Started process for discovery of books....\n");
    BookwormApp.Settings settings = BookwormApp.Settings.get_instance();
    ArrayList<string> scanDirList = new ArrayList<string>();
    //find the folders to scan from the settings
    if(BookwormApp.Bookworm.settings.list_of_scan_dirs.length > 1){
      debug(settings.list_of_scan_dirs);
			string[] scanDirArray = settings.list_of_scan_dirs.split ("~~");
      foreach (string token in scanDirArray){
        scanDirList.add(token);
      }
		}
    //create the find command
    StringBuilder findCmd = new StringBuilder("find ");
    foreach (string scanDir in scanDirList) {
      if(scanDir != null && scanDir.length > 1){
        findCmd.append("\"").append(scanDir).append("\"").append(" ");
      }
    }
    findCmd.append("! -readable -prune -o -type f \\( -iname \\*.pdf -o -iname \\*.epub -o -iname \\*.cbr -o -iname \\*.cbz \\) -print");
    string findCmdOutput = BookwormApp.Utils.execute_sync_command(findCmd.str);
    if(findCmdOutput.contains("\n")){
      string[] findCmdOutputResults = findCmdOutput.strip().split ("\n",-1);
      ArrayList<string> listOfBooks = BookwormApp.DB.getBookIDListFromDB();
      //check if the database exists otherwise create database and required tables
  		bool isDBPresent = BookwormApp.DB.initializeBookWormDB(GLib.Environment.get_user_config_dir ()+"/bookworm");
      foreach (string findResult in findCmdOutputResults) {
        bool noMatchFound = true;
        foreach (string book in listOfBooks) {
          if(book.contains(findResult)){
            noMatchFound = false;
            break;
          }
        }
        if(noMatchFound){
          debug("Attempting to add book located at:"+findResult);
          BookwormApp.Book aBook = new BookwormApp.Book();
          aBook.setBookLocation(findResult);
          File eBookFile = File.new_for_path (findResult);
          if(eBookFile.query_exists() && eBookFile.query_file_type(0) != FileType.DIRECTORY){
            int bookID = BookwormApp.DB.addBookToDataBase(aBook);
    				aBook.setBookId(bookID);
            aBook.setBookLastModificationDate((new DateTime.now_utc().to_unix()).to_string());
            aBook.setWasBookOpened(true);
            //parse eBook to populate cache and book meta data
            aBook = BookwormApp.Bookworm.genericParser(aBook);
            if(!aBook.getIsBookParsed()){
              BookwormApp.DB.removeBookFromDB(aBook);
            }else{
              BookwormApp.DB.updateBookToDataBase(aBook);
              debug("Sucessfully added book located at:"+findResult);
            }
          }
        }
      }
    }
  }
}
