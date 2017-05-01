# bookworm
A simple eBook Reader application made for elementary OS

Author: Siddhartha Das

The goal of Bookworm is to provide a uniform user experience for multiple electronic document formats like epub,pdf, mobi, etc. Currently Bookworm is in a very draft stage with support for epub format only.

## How to install bookworm:

```shell
sudo add-apt-repository ppa:bookworm-team/bookworm
sudo apt-get update
sudo apt-get install bookworm
```

## How to build bookworm:

```shell
sudo apt-get build-dep granite-demo 
sudo apt-get install libgranite-dev
sudo apt-get install valac
sudo apt-get install libwebkit2gtk-4.0-37 libwebkit2gtk-4.0-dev
sudo apt-get install sqlite3 libsqlite3-dev
sudo apt-get install poppler-utils libpoppler-glib-dev

git clone https://github.com/babluboy/bookworm.git
cd bookworm
mkdir build && cd build 
cmake -DCMAKE_INSTALL_PREFIX=/usr ../
make
```
## Screenshots

![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/master/screenshots/BookwormLibraryView.jpeg)
![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/master/screenshots/BookwormReadingView.jpeg)

Bookworm in Night View Mode

![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/master/screenshots/BookwormLibraryViewNightView.jpeg)
![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/master/screenshots/BookwormReadingViewNightView.jpeg)

Selection for deleting books from the library

![screenshot](https://raw.githubusercontent.com/babluboy/bookworm/master/screenshots/BookwormLibraryViewSelectionMode.jpeg)
