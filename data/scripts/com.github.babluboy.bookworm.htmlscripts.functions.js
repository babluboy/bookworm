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
