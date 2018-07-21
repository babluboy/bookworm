search_word=$1
#check if the input still has spaces i.e. multiple words
case "$search_word" in  
     *\ * )
           #space found in input - send output warning and quit
           echo "Multiple words are not supported, please search for a single word"
           exit
          ;;
       *)
           #do nothing - the input has no spaces
           ;;
esac
#
#
#The section below is for online dictionary. For offline dictionary, comment this section and uncomment the section below
curl -s http://wordnetweb.princeton.edu/perl/webwn?s="$search_word" | html2text -o /tmp/bookworm_word_search.txt > /dev/null
#split the output to remove unwanted header information i.e anything before **** Noun ****
csplit -s -f /tmp/search_result_ /tmp/bookworm_word_search.txt /"[****]*[****]"/ > /dev/null
cat /tmp/search_result_01
#remove the files created by this script
rm -f /tmp/search_result_00 /tmp/search_result_01  /tmp/bookworm_word_search.txt
#
#
#The section below is for offline dictionary.Ensure dictionary is installed by running the following command:
#sudo apt-get install dictd dict dict-gcide
#Run offline dictionary by enabling the line below:
#dict $search_word
