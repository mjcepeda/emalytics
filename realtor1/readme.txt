Working environment: 	Anaconda command line on windows 10
Repos needed to run :	pip install scrapy_proxies #random proxy addresses - > existing code was changed to better suit our purpose
			pip install scrapy-random-useragent #random user-agents - > existing source code was changed to better suit our purpose
Spider :  		./realtor1/spiders/realtor_spider.py #main crawler used to extract urls and parse HTML using XPath
settings :		./realtor1/settings.py #changes were made here to incorporate rotating user-agents and random proxies as well as define error messages for retry_procedure_Calls and initializing a delay counter 
Middlewares.py : 	./realtor1/middlewares.py # defined function call to rotate user agents 
items.py :		./realtor1/items.py # defined data structure for write_to_disk operation
realtor3.csv : 		#scrapped data
proxies.txt : 		#defined proxy list in the format http://host:port
