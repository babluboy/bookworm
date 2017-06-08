/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and will be used to clean up
* cache data for extracted contents of books and cover images
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
public class BookwormApp.Cleanup {
  public static ArrayList<string> bookIDList = new ArrayList<string> ();
  public static void cleanUp(){
    //get list of Book IDs in DB
    bookIDList = BookwormApp.DB.getBookIDListFromDB();
    cleanBookCacheContent();
    cleanBookCoverImages();
  }

  public static void cleanBookCacheContent(){
    //list the folders in the cache
    string cacheFolders = BookwormApp.Utils.execute_sync_command("ls -1 " + BookwormApp.Bookworm.bookworm_config_path + "/books/");
    cacheFolders = cacheFolders.replace("\r", "^^^").replace("\n", "^^^");
    string[] cacheFolderList = cacheFolders.split("^^^");
    //loop through each folder name
    bool folderMatched = false;
    foreach (string cacheFolder in cacheFolderList) {
      folderMatched = false;
      cacheFolder = cacheFolder.strip();
      if(cacheFolder == null || cacheFolder.length < 1){
        folderMatched = true;
      }
      foreach (string bookData in bookIDList){
        if(cacheFolder != null && cacheFolder.length > 0){
          //check if the folder is part of a book in the library
          if((bookData.split("::")[1]).index_of(cacheFolder) != -1){
            folderMatched = true;
            break;
          }
        }
      }
      if(!folderMatched){
        //delete the folder and content if it is not a part of any book in the library
        BookwormApp.Utils.execute_sync_command("rm -Rf \"" + BookwormApp.Bookworm.bookworm_config_path + "/books/" + cacheFolder + "\"");
        debug ("Cache Folder deleted:"+cacheFolder);
      }
    }
  }

  public static void cleanBookCoverImages(){
    //list the cover images in the cache
    string cacheImages = BookwormApp.Utils.execute_sync_command("ls -1 " + BookwormApp.Bookworm.bookworm_config_path + "/covers/");
    cacheImages = cacheImages.replace("\r", "^^^").replace("\n", "^^^");
    string[] cacheImageList = cacheImages.split("^^^");
    //loop through each cover image in cache
    bool imageMatched = false;
    foreach (string cacheImage in cacheImageList) {
      imageMatched = false;
      cacheImage = cacheImage.strip();
      if(cacheImage == null || cacheImage.length < 1){
        imageMatched = true;
      }
      foreach (string bookData in bookIDList){
        if(cacheImage != null && cacheImage.length > 0){
          //check if the folder is part of a book in the library
          if(cacheImage.index_of((bookData.split("::")[0])) != -1){
            imageMatched = true;
            break;
          }
        }
      }
      if(!imageMatched){
        //delete the folder and content if it is not a part of any book in the library
        BookwormApp.Utils.execute_sync_command("rm -f \"" + BookwormApp.Bookworm.bookworm_config_path + "/covers/" + cacheImage + "\"");
        debug ("Cache Image deleted:"+cacheImage);
      }
    }
  }

}
