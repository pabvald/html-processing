LDLIBS=-lfl
dir = test

all: 	
		@make clean 
		@make executable
		@make testing	
		
		
executable:	
		make htmlinfo
		rm -f lex.yy.c
			
		
testing: download
		./htmlinfo $(dir)/uva.html
		./htmlinfo $(dir)/tutorial.html 
		./htmlinfo $(dir)/github.html


download: 
		mkdir -p $(dir)
		cd $(dir); \
		wget -q --output-document=uva.html http://www.uva.es/export/sites/uva/2.docencia/2.01.grados/2.01.02.ofertaformativagrados/2.01.02.01.alfabetica/index.html ; \
		wget -q --output-document=tutorial.html https://www.tutorialspoint.com/c_standard_library/c_function_fscanf.htm; \
		wget -q --output-document=github.html https://github.com/;


clean:
		rm -fr test
		rm -f htmlinfo