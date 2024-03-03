install-check: 

ifeq (, $(shell which curl))
	@echo No curl is installed, curl will be installed now.... 
	@sudo apt-get install curl -y
endif

ifeq (,$(shell which $(HOME)/bin/dfx))	
	@echo No dfx is installed, dfx will be installed now....
	curl -fsSL https://internetcomputer.org/install.sh -o install_dfx.sh
	chmod +x install_dfx.sh
	./install_dfx.sh
	rm install_dfx.sh		
endif

ifeq (, $(shell which nodejs))
	sudo apt install nodejs -y
endif

ifeq (, $(shell which npm))
	sudo apt install npm -y
endif

ifeq (, $(shell which mops))
	sudo npm i -g ic-mops
endif

ifeq (, $(shell which $(HOME)/bin/vessel))	
	rm installvessel.sh -f
	echo '#install vessel'>installvessel.sh
	echo cd $(HOME)/bin>>installvessel.sh
	echo wget https://github.com/dfinity/vessel/releases/download/v0.7.0/vessel-linux64 >> installvessel.sh
	echo mv vessel-linux64 vessel >>installvessel.sh
	echo chmod +x vessel>>installvessel.sh
	chmod +x installvessel.sh
	./installvessel.sh
	rm installvessel.sh -f
endif	

	mops add memory-buffer
	mops add test
	mops add memory-region
	mops update
	dfx upgrade