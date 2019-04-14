# HTML files processing with Lex


## Usage
`./hmlinfo <html file> `

## Output 
 Once the HTML file is processed, the following output will be provided:
 
  - **FILE**: file name
  - **TITLE**: title of the html file, contained in the <title> tag.
  - **TAGSTATS**: tag name and number of ocurrences separated by a space. The *DOCYPE* tag and the comment tag won't be included in the stats.
  - **LINKS**: list of the URLs contained in the *<script>*, *<link>* and *<a>* tags.
  - **IMAGES**: list of the URLs contained in the *<image>* tag.
  


