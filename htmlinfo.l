%{
 // BEGIN DECLARATIONS //

#include <stdio.h>
#include <ctype.h>

struct LinkedList{
    int counter;
    char *text;
    struct LinkedList *next;
};

typedef struct LinkedList *node;    //Define node as pointer of data type struct LinkedList


/* Input files list */
int nInputFiles = 0;
int nInFile = 0;
char **inputFiles = NULL;
char *inFileName = NULL;

/* FILE section */
FILE *infoFile = NULL;
char *infoFileName = NULL;

/* TITLE section */
char *title = NULL; 

/* TAGSTATS section */
node TAGS = NULL;   //Tags simple linked list 

/* LINKS section  */    
char *base = "";  //<base> href attribute value
node URLS = NULL;  //Links simple linked list

/* IMAGES section */
node IMAGES = NULL; //Images simple linked list


/* Functions declarations */
void ignoreComments(void);
void addTag(char *);
void addLink(char *, int );
void addImage(char *, int );
void addURL(node , char *, int);
void toLowerCase(char *);
void resetVariables(void);
node createNode(void);

 // END DECLARATIONS //
%}
 
SPACE       [ \t]+

REL_URL     [a-z0-9\-\._~:\/\?#\[\]@!\$&'\(\)\*\+,;=\%]+
ABS_URL     (http|https):\/\/{REL_URL}
HTML_TAG    [a-z0-9\+#\-\.]+

OPLT    \<
OPGT    \>
SLASH   \/
DQUOTE  \"


OPEN_COMMENT        {OPLT}!\-\-

OPEN_TITLE          {OPLT}title({SPACE}|[^\>])*{OPGT}

DOCTYPE_TAG         {OPLT}!DOCTYPE({SPACE}|{DQUOTE}|{REL_URL})*{OPGT}  

OPEN_IMG            {OPLT}img
OPEN_SCRIPT         {OPLT}script
OPEN_STYLE          {OPLT}style
OPEN_LINK           {OPLT}link
OPEN_A              {OPLT}a 
OPEN_BASE           {OPLT}base

HREF_OPEN           href{SPACE}*={SPACE}*{DQUOTE}?
SRC_OPEN            src{SPACE}*={SPACE}*{DQUOTE}?

%S TITLE_TEXT
%S IMG_SRC
%S SCRIPT_SRC
%S CODE
%S A_HREF
%S LINK_HREF
%S BASE_HREF
%S TAG
%option caseless
%% 

 /* Comments - When a comment starts, the input is ignored until the comment is closed */
{OPEN_COMMENT}  { ignoreComments(); }

 /* Ignores <!DOCTYPE ..> tag */
{DOCTYPE_TAG}    ;

 /* Title - Saves the text between the title tags in the variable titleSte */
{OPEN_TITLE}                                { BEGIN TITLE_TEXT;         addTag("title"); }
<TITLE_TEXT>.*/"</"                         { title = strdup(yytext);   BEGIN 0;  }


 /* <base> URL - Gets the URL base if it exists.*/
{OPEN_BASE}(SPACE|[^>])*{HREF_OPEN}     { BEGIN BASE_HREF;         addTag("base"); }
<BASE_HREF>{REL_URL}                    { base = strdup(yytext);   BEGIN 0; }


 /*<a> URL - Saves the <a> tags href value */
{OPEN_A}({SPACE}|[^>])*{HREF_OPEN}      { BEGIN A_HREF;           addTag("a"); }
<A_HREF>{ABS_URL}                       { addLink(yytext, 0);     BEGIN 0;}
<A_HREF>{REL_URL}                       { addLink(yytext, 1);     BEGIN 0;}


 /*<link> URL - Saves the <link> tags href value */
{OPEN_LINK}({SPACE}|[^>])*{HREF_OPEN}   { BEGIN LINK_HREF;       addTag("link");}
<LINK_HREF>{ABS_URL}                    { addLink(yytext, 0);    BEGIN 0; }
<LINK_HREF>{REL_URL}                    { addLink(yytext, 1);    BEGIN 0; }

 /* Images - Saves the image src value */
{OPEN_IMG}({SPACE}|[^>])*{SRC_OPEN}     { BEGIN IMG_SRC;          addTag("img");  }
<IMG_SRC>{ABS_URL}                      { addImage(yytext, 0);    BEGIN 0; }
<IMG_SRC>{REL_URL}                      { addImage(yytext, 1);    BEGIN 0; } 


 /* Ignores the input until a close tag is found */
<CODE>[^\<\n]*                    ;
<CODE>{OPLT}+[^/\n]*	          ;
<CODE>\n		                  ;
<CODE>{OPLT}\/	                  BEGIN(0);


 /*<script> URL - Saves the <script> tags href value and ignores the code in the script if it exists */
{OPEN_SCRIPT}({SPACE}|[^>])*{SRC_OPEN}     { BEGIN SCRIPT_SRC;       addTag("script"); }
{OPLT}script({SPACE})*{OPGT}               { BEGIN CODE;             addTag("script");}
<SCRIPT_SRC>{ABS_URL}/.*">"                { addLink(yytext, 0);     BEGIN 0;  BEGIN CODE;}
<SCRIPT_SRC>{REL_URL}/.*">"                { addLink(yytext, 1);     BEGIN 0;  BEGIN CODE;}


 /* Ignore <style> content */
{OPEN_STYLE}.*/">"           { addTag("style");    BEGIN CODE; }

 
        
 /* Other tags */
{OPLT}/[^/]                  BEGIN TAG; 
<TAG>{HTML_TAG}            { addTag(yytext);  BEGIN 0;}

.   ;
\n  ;

%% 

 /**
  *     MAIN PROGRAM
  */
 int main(int argc, char **argv) {
    
    nInputFiles = argc - 1,
    inputFiles = (char **) malloc(nInputFiles * sizeof(char *));

    int i;
    for(i = 0; i < argc; i++) 
        inputFiles[i-1] = strdup(argv[i]);

    nInFile = 0;
    if (nInputFiles > 0) {
        inFileName = inputFiles[nInFile++];
        yyin = fopen(inFileName, "r");
    }
    
    yylex();
 }   

 /**
  * It is called by yylex() every time the input ends.
  * @return 0 if there are more files to process; 1 if there aren't.
  */
 int yywrap(void) {         
  
    if (inFileName) fclose(yyin);

    //Build .info file name
    infoFileName = strdup(inFileName);
    infoFileName = strtok(infoFileName,".");
    strcat(infoFileName,".info");  

    //Create and open .info file in 'write' mode
    infoFile = fopen(infoFileName, "w");

    if (infoFile == NULL ) {
        fprintf(stderr, "Error: %s cannot be written\n", infoFileName );
    } else {
        /*Print the informartion in the info file */

        int i;
        node tempNode;
        
        /* Print file name  */
        fprintf(infoFile,"FILE: %s\n", inFileName);
     
        /* Print page title */
        fprintf(infoFile,"TITLE: %s\n", title);

        /* Print tag statistics */
        fprintf(infoFile,"TAGSTATS: \n");
        tempNode = TAGS;
        while(tempNode != NULL) {
            fprintf(infoFile,"<%s> %d\n", tempNode->text, tempNode->counter);
            tempNode = tempNode->next;
        }                  
                
        /* Print links */
        fprintf(infoFile,"LINKS: \n");
        tempNode = URLS;
        while(tempNode != NULL) {
            if(tempNode->counter ) fprintf(infoFile,"<REL>%s%s\n", base, tempNode->text);            
            else fprintf(infoFile,"%s\n", tempNode->text);
            tempNode = tempNode->next;
        }      

        /* Print images */
        fprintf(infoFile,"IMAGES: \n");        
        tempNode = IMAGES;
        while(tempNode != NULL) {
            if(tempNode->counter) fprintf(infoFile,"<REL>%s%s\n", base, tempNode->text);            
            else fprintf(infoFile,"%s\n", tempNode->text);
            tempNode = tempNode->next;
        }        
    }          

    // There isn't any more input files
    if (nInFile >= nInputFiles) return 1;

    resetVariables();
    inFileName = inputFiles[nInFile++];
    yyin = fopen(inFileName, "r");

    return 0;
 } 
 

 /**
  * It creates a new node.
  * @return new node with the 'next' member initialized to NULL.
  *
  * @author Pablo Valdunciel Sánchez
  */
 node createNode() {
    node temp; // Declare a node
    temp = (node)malloc(sizeof(struct LinkedList)); // Allocate memory using malloc()
    temp->next = NULL;  
    return temp;
 }


 /**
  * It is called every time a open comment tag ('<!--') is found. 
  * The input is ignored until the close comment tag ('-->') is found.
  *
  * @author Valentín Cardeñoso Payo
  */
 void ignoreComments() {
    
    int c1, c2, c3; 
	int done = 0;
	
	while(!done) {
		switch(c1 = input()) {
			/* EOF: Bad comment */
			case EOF:
				fprintf(stderr, "___ERROR: unclosed comment, expect -->\n");
				done = 1 ;
			break;

            /* Possible end of comment */
			case '-':   
				if((c2 = input()) == '-' && (c3 = input()) == '>') {  done = 1; }
				else { unput(c2);  unput(c3); }
			    break;

            /* INSIDE comment - Don't do anything */
			default:   
				break;
		}
	}
 }
 
 /**
  * It counts the ocurrence of a given tag. If the tag is already 
  * stored, its counter is increased by 1; if it isn't stored, the tag is added 
  * to the linked list TAGS.
  * @param str - string containing the tag.
  *
  * @author Pablo Valdunciel Sánchez
  */
 void addTag(char *str) {      

    node temp, n, last;
    int found = 0;
    int comp;
    char *tagName = strdup(str); 
    toLowerCase(tagName);
    
    if(TAGS == NULL) {
       temp = createNode();
       temp->counter = 1;
       temp->text = tagName;
       TAGS = temp;
    } else {
        last = NULL;    
        n = TAGS;
        do {           
            comp = strcmp(n->text, tagName);
            if (comp > 0) {   // n->text > tagName
                //Insert tag before n
                temp = createNode();
                temp->counter = 1;
                temp->text = tagName;
                temp->next = n;
                if(last == NULL) { TAGS = temp;}
                else {last->next = temp;}
                found = 1;
            } else if(comp == 0) {   //n->text == tagName      
                n->counter = (n->counter) + 1;  // The tag is already stored
                found = 1;
            } else {    // comp == 1; n->text < tagName 
                last = n;
                n = n->next;
            }                
        } while(n != NULL && !found);
        
        if(!found) { //The end of the list has been reached
            temp = createNode();
            temp->counter = 1;
            temp->text = tagName;
            last->next = temp;
        }       
    }
 }
 
 /**
  * It stores a given URL in a given linked list. If the URL is already 
  * stored in the list, nothing is done.
  * @param head - first node of the linked list 
  * @param str - URL to be stored
  * @param relative - 1 if the URL is relative; 0 if it is absolute
  *
  */
 void addURL(node list, char *str, int relative) {
    node temp, n, last;
    int found = 0;
    char *url = strdup(str);

    n = list;
    do {
        if(strcmp(n->text, url) == 0) { found = 1; }
        last = n;
        n = n->next;
    } while(n != NULL && !found);

    if(!found) {
        temp = createNode();
        temp->text = url;
        temp->counter = relative;
        last->next = temp;
    }
 }

 /**
  * It counts the ocurrence of a given link. If the URL isn't stored, it is added 
  * to the linked list URLS; if it is already stored, nothing is done.
  * @param str - string containing the link URL. 
  * @param relative - 1 if the URL is relative, 0 if it is absolute
  *
  * @author Pablo Valdunciel Sánchez
  */
 void addLink(char *str, int relative ) {  

    if(URLS == NULL) {
        node temp, n, last;
        int found = 0;
        char *link = strdup(str);

        temp = createNode();
        temp->text = link;
        temp->counter = relative;
        URLS = temp;
    } else {
        addURL(URLS, str, relative);
    }
 }

 /**
  * It counts the ocurrence of a given image. If the URL isn't stored, the image URL  is added 
  * to the linked list IMAGES; if it is already stored, nothing is done.
  * @param str - string containing the image URL.
  * @param relative - 1 if the URL is relative, 0 if it is absolute
  *
  * @author Pablo Valdunciel Sánchez
  */
 void addImage(char *str, int relative) {
    
    if(IMAGES == NULL) {
        node temp, n, last;
        int found = 0;
        char *img = strdup(str);

        temp = createNode();
        temp->text = img;
        temp->counter = relative;
        IMAGES = temp;
        
    } else {
        addURL(IMAGES, str, relative);
    }
 }
 

 /**
  * It modifies a string, converting it to uppercase using the function 
  * 'int tolower(int *c)'.
  * @param str - string to be converted.
  *
  * @author Pablo Valdunciel Sánchez
  */
 void toLowerCase(char *str) {
    for(int i = 0; str[i]; i++){
        str[i] = tolower(str[i]);
    }
 }

 /**
  * It frees the allocated memory and sets  certain variables to NULL
  * before processing another file.
  * 
  * @author Pablo Valdunciel Sánchez
  */
 void resetVariables(void) {
    free(TAGS);
    free(URLS);
    free(IMAGES);
    free(base);
    free(title);
    TAGS = NULL;
    URLS = NULL;
    IMAGES = NULL;
    base = NULL;
    title = NULL;
 }
