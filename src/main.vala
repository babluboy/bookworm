/* Copyright 2017 Siddhartha Das (bablu.boy@gmail.com)
*
* This file is part of Bookworm and entry point to the
* application with the main method
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
BookwormApp.Bookworm application;
public static int main (string[] args) {
  Environment.set_variable ("G_MESSAGES_DEBUG", "all", true);
  if("--debug" in args){
    Log.set_handler ("", GLib.LogLevelFlags.LEVEL_DEBUG, GLib.Log.default_handler);
    debug ("Bookworm Application running in debug mode - all debug messages will be displayed");
  }
  if("--info" in args){
    Log.set_handler ("", GLib.LogLevelFlags.LEVEL_INFO, GLib.Log.default_handler);
    debug ("Bookworm Application running in info mode - all info messages will be displayed");
  }
  application = application.getAppInstance();
  //Workaround to get Granite's --about & Gtk's --help working together
  if ("--help" in args || "-h" in args || "--version" in args || "--discover" in args) {
    return application.processCommandLine (args);
  } else {
    Gtk.init (ref args);
    return application.run(args);
  }
}
