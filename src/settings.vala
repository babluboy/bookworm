/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and is used for persisting
* the state of the window and associated user prefferences
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

public class BookwormApp.Settings : Granite.Services.Settings {
  private static Settings? instance = null;

  public int window_width { get; set; }
  public int window_height { get; set; }
  public int pos_x { get; set; }
  public int pos_y { get; set; }
  public bool window_is_maximized { get; set; }
  public double zoom_level { get; set; }
  public string reading_profile { get; set; }
  public bool is_local_storage_enabled { get; set; }
  public string reading_width { get; set; }

  public static Settings get_instance () {
    if (instance == null) {
        instance = new Settings ();
    }
    return instance;
  }

  private Settings () {
    base (BookwormApp.Constants.bookworm_id);
  }
}
