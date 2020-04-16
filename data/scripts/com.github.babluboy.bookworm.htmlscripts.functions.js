var is_search_result_found = "false";

function setTwoPageView() {
    var lengthOfData = document.getElementsByTagName("BODY")[0].innerText.length;
    if(lengthOfData > 500){
        document.getElementsByTagName("BODY")[0].className = "two_page";
    }
}

function overlayAnnotation(annotationText) {
    annotationText = decodeURIComponent (annotationText);
    //attempt to find and highlight the whole phrase
    var originalAnnotationText = annotationText;
    findAndReplace(annotationText, "<a href='#' onclick='javascript:document.title=\"annotation:"+originalAnnotationText+"\"'><span class='bookworm_annotation_highlight'>"+annotationText+"</span></a>");
    while(is_search_result_found == "false" && annotationText.length > 2){
        //whole phrase is not found, retry after removing one character from left and right
        annotationText = annotationText.slice(1, -1).trim();
        findAndReplace(annotationText, "<a href='#' onclick='javascript:document.title=\"annotation:"+originalAnnotationText+"\"'><span class='bookworm_annotation_highlight'>"+annotationText+"</span></a>");
    }
    var resultText = document.getElementsByClassName("bookworm_annotation_highlight")[0];
    resultText.scrollIntoView();
}

function highlightText(highlightText) {
    highlightText = decodeURIComponent (highlightText);
    //attempt to find and highlight the whole phrase
    findAndReplace(highlightText, "<span class='bookworm_search_result_highlight'>"+highlightText+"</span>");
    while(is_search_result_found == "false" && highlightText.length > 2){
        //whole phrase is not found, retry after removing one character from left and right
        highlightText = highlightText.slice(1, -1).trim();
        findAndReplace(highlightText, "<span class='bookworm_search_result_highlight'>"+highlightText+"</span>");
    }
    //highlight phrase and scroll it to view
    var resultText = document.getElementsByClassName("bookworm_search_result_highlight")[0];
    resultText.scrollIntoView();
}

function scrollToSearchText(searchText) {
    findAndReplace(searchText, "<span class='bookworm_search_result_scroll'>"+searchText+"</span>");
    var resultText = document.getElementsByClassName("bookworm_search_result_scroll")[0];
    resultText.scrollIntoView();
}

RegExp.escape= function(s) {
    return s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');
};

function findAndReplace(searchText, replacement, searchNode) {
    if (!searchText || typeof replacement === 'undefined') {
        // Throw error here if you want...
        return;
    }
    var regex = typeof searchText === 'string' ?
        new RegExp(RegExp.escape(searchText), 'ig') : searchText,
        childNodes = (searchNode || document.body).childNodes,
        cnLength = childNodes.length,
        excludes = 'html,head,style,title,link,meta,script,object,iframe';
    while (cnLength--) {
        var currentNode = childNodes[cnLength];
        if (currentNode.nodeType === 1 &&
            (excludes + ',').indexOf(currentNode.nodeName.toLowerCase() + ',') === -1) {
            arguments.callee(searchText, replacement, currentNode);
        }
        if (currentNode.nodeType !== 3 || !regex.test(currentNode.data) ) {
            continue;
        }
        var parent = currentNode.parentNode,
        frag = (function(){
            var matchedResult = new RegExp(RegExp.escape(searchText), 'ig').exec(currentNode.data);
            is_search_result_found = "true";
            replacement = replacement.replace(searchText, matchedResult[0]),
            wrap = document.createElement('div'),
            frag = document.createDocumentFragment();
            wrap.innerHTML = html;
            var html = currentNode.data.replace(regex, replacement),
            wrap = document.createElement('div'),
            frag = document.createDocumentFragment();
            wrap.innerHTML = html;
            while (wrap.firstChild) {
                frag.appendChild(wrap.firstChild);
            }
            return frag;
        })();
        parent.insertBefore(frag, currentNode);
        parent.removeChild(currentNode);
    }
}
function getSelectionText() {
    var text = "";
    if (window.getSelection) {
        text = window.getSelection().toString();
    } else if (document.selection && document.selection.type != "Control") {
        text = document.selection.createRange().text;
    }
    return text;
}
//These section is for pagination
var pageStart = 0;
var pageEnd = 0;
var splitContent=[];

function checkOverflow(el){
	var curOverflow = el.style.overflow;
	if ( !curOverflow || curOverflow === "visible" )
		el.style.overflow = "hidden";
	var isOverflowing = el.clientWidth < el.scrollWidth 
	|| el.clientHeight < el.scrollHeight;
	el.style.overflow = curOverflow;
	return isOverflowing;
}
function splitInput( input ) {
	// split the input into an array of tags containing arrays of words
	input = input.replace(/(\r\n\t|\n|\r\t)/gm,"");
	var words = [];
	while ( input.length > 0 ) {
		if ( input.charAt( 0 ) == "<" ) {
				words.push( input.substr( 0, input.indexOf( ">") + 1 ) );
				input = input.substr( input.indexOf( ">") + 1 ).trim();
				var next = indexOfMultiple( input, " <" )
				words[ words.length - 1 ] += input.substr( 0, next ); // attach tags to their closest word
				input = input.substr( next ).trim();
		}
		var next = indexOfMultiple( input, " <" )
		words.push( input.substr( 0, next ) );
		input = input.substr( next ).trim();
	}
	return words;
}
function indexOfMultiple( str, compare ) {
	// finds index of first occurence of a character in compare
	for( var i = 0; i < str.length; i++ ) {
		var c = str.charAt(i);
		for ( var j = 0; j < compare.length; j++ ) {
			if ( c == compare[ j ] ) {
				return i;
			}
		}
	}
	return str.length;
}
function fillPage( page, direction ) {
	var oldContent = "";
	var newContent = "";
	page.innerHTML = "";
	while ( ! checkOverflow( page ) ) {
		// fill the page until it overflows
		if ( ( pageEnd >= splitContent.length ) && ( direction == "forward" ) ) {
			return;
		}
		oldContent = newContent;
		newContent = "";
		for ( var i = pageStart; i < pageEnd; i++ ) {
			newContent += splitContent[ i ] + " ";
		}
		page.innerHTML = newContent;
		if ( direction == "forward" ) {
			pageEnd++;
		}
		if ( direction == "back" ) {
			pageStart--;
			if ( pageStart <= 0 ) {
				pageStart = 0;
				direction = "forward";
			}
		}
	}
	page.innerHTML = oldContent;
	if ( oldContent.charAt( 0 ) != "<" ) {
		// put beginning tags if missing
		var i = pageStart;
		while (
	        ( splitContent[ i ].charAt( i ) != "<" ) || 
	        ( splitContent[ i ].substr( 0, 2 ) == "</" ) 
        ) {
		    i--;
	    }
		page.innerHTML = splitContent[ i ] + oldContent;
	}
	pageEnd-=2;
}
function forward() {
    if(pageEnd >= splitContent.length){
        //set the title to mark the end of the split page
        document.title=":END:pageStart="+pageStart+",pageEnd="+pageEnd+",splitContent.length="+splitContent.length;
	    return;
    }
    pageStart = pageEnd;
    fillPage( document.getElementById( "page" ), "forward" );
    document.title=":CONTINUE:pageStart="+pageStart+",pageEnd="+pageEnd+",splitContent.length="+splitContent.length;
}
function back() {
    if(pageStart <= 0){
        //set the title to mark the start of the split page
        document.title=":START:pageStart="+pageStart+",pageEnd="+pageEnd+",splitContent.length="+splitContent.length;
	    return;
	}
    pageEnd = pageStart;
	fillPage( document.getElementById( "page" ), "back" );
	document.title=":CONTINUE:pageStart="+pageStart+",pageEnd="+pageEnd+",splitContent.length="+splitContent.length;
}
function init_pagination() {
	var page = document.getElementById( "page" );
	splitContent = splitInput( page.innerHTML );
	page.innerHTML = "";
	fillPage( page, "forward" );
}
