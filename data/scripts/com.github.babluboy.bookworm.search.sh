#!/bin/bash
#Written by Siddhartha Das (bablu.boy@gmail.com) as part of Bookworm (eBook Reader)
#This script searches through the contents of a book for the user provided text
#html2text utility is used to extract the text from the html content and html entities de-coded

HTML_CONTENT_TO_BE_SEARCHED=$1
USER_SEARCH_TEXT=$2
html2text -utf8 "$HTML_CONTENT_TO_BE_SEARCHED"  | tr '\n' ' ' | grep -E -o -i  ".{0,50}$USER_SEARCH_TEXT.{0,50}"
