from lxml import html

import unicodecsv as csv
from random import randint
import time
import requests
import json

#from exceptions import ValueError

#from time import sleep

import re

import argparse

def scraper(parser, item_position, items_per_page):
    '''json data that contains longitude and latitude'''
    list_script = parser.xpath('//script[contains(., "yelp.www.init.search.Controller")]//text()')
    jsonContent = None
    if len(list_script)>0:
        script = list_script[0]
        script= re.sub("yelp.www.init.search.Controller\(", "", script)
        script= re.sub("\);", "", script)   
        script = "".join([script.rsplit("}" , 1)[0] , "}"])  
        jsonContent = json.loads(script)
    
    '''data about every item'''
    listing = parser.xpath("//li[@class='regular-search-result']")
    scraped_datas=[]

    for results in listing:

        raw_position = results.xpath(".//span[@class='indexed-biz-name']/text()")    

        raw_name = results.xpath(".//span[@class='indexed-biz-name']/a//text()")

        raw_ratings = results.xpath(".//div[contains(@class,'rating-large')]//@title")

        raw_review_count = results.xpath(".//span[contains(@class,'review-count')]//text()")

        raw_price_range = results.xpath(".//span[contains(@class,'price-range')]//text()")

        category_list = results.xpath(".//span[contains(@class,'category-str-list')]//a//text()")

        raw_address = results.xpath(".//address//text()")

        relative_url = results.xpath(".//span[@class='indexed-biz-name']/a/@href")[0]
        url = "https://www.yelp.com"+relative_url
        
        '''matching latitude and longitude data with item'''
        raw_latitude = 0
        raw_longitude = 0
        if jsonContent != None:
            search_map = jsonContent['searchMap']
            if 'markers' in search_map:
                limit = item_position + items_per_page + 1
                for index in range(item_position+1,limit,1):
                    if str(index) in search_map['markers']:
                        if 'url' in search_map['markers'][str(index)]:
                            if jsonContent['searchMap']['markers'][str(index)]['url'] == relative_url:
                                raw_longitude = jsonContent['searchMap']['markers'][str(index)]['location']['longitude']
                                raw_latitude = jsonContent['searchMap']['markers'][str(index)]['location']['latitude']
            
        
        name = ''.join(raw_name).strip()

        position = ''.join(raw_position).replace('.','').replace('\n', '').strip()

        cleaned_reviews = ''.join(raw_review_count).strip()

        reviews =  re.sub("\D+","",cleaned_reviews)

        categories = ','.join(category_list) 

        cleaned_ratings = ''.join(raw_ratings).strip()

        if raw_ratings:
            ratings = re.findall("\d+[.,]?\d+",cleaned_ratings)[0]
        else:
            ratings = 0

        price_range = len(''.join(raw_price_range)) if raw_price_range else 0

        address  = ' '.join(' '.join(raw_address).split())
        
        longitude = raw_longitude
        latitude = raw_latitude
        
        data={
            'business_name':name,
            'rank':position,
            'review_count':reviews,
            'categories':categories,
            'rating':ratings,
            'address':address,
            'longitude':latitude,
            'latitude':longitude,
            'price_range':price_range,
            'url':url
        }
        scraped_datas.append(data)

    return scraped_datas


def parse(search_query):
    
    url = "https://www.yelp.com/search?find_loc=Miami,+FL,+US&cflt="+search_query
    
    ''' Different url for coffee'''
    #url = "https://www.yelp.com/search?find_desc=Coffee+%26+Tea&find_loc=Miami,+FL&start=0"
    response = requests.get(url).text

    parser = html.fromstring(response)

    print ("Retrieving :", url)
    print ("Parsing page 1")
     
    ''' Extracting information about total results '''
    raw_total_results = parser.xpath("//span[@class='pagination-results-window']//text()")
    results = ''.join(raw_total_results).replace('\n', '').strip()
    temp_total_result = results.split(sep='-', maxsplit=1)
    first_item = temp_total_result[0]
    first_item = re.sub("\D+","",first_item)
    last_item=temp_total_result[1].split(sep='of', maxsplit=1)[0]
    last_item = re.sub("\D+","",last_item)
    
    items_per_page=(int(last_item)-int(first_item))+1
    total_result = int(temp_total_result[1].split(sep='of', maxsplit=1)[1])
    
    scraped_data=[]
    '''scraping data from the first page'''
    scraped_data.extend(scraper(parser, 0, items_per_page))
    
    count=2
    ''' now, scraping data from the rest of the pages'''
    for item in range(items_per_page+1,total_result+1,items_per_page):
        new_url = "https://www.yelp.com/search?find_loc=Miami,+FL,+US&start="+str(item)+"&cflt="+search_query
        #new_url = "https://www.yelp.com/search?find_desc=Coffee+%26+Tea&find_loc=Miami,+FL&start="+str(item)
        response = requests.get(new_url).text
        print ("Parsing page " + str(count))
        parser = html.fromstring(response)
        scraped_data.extend(scraper(parser, item, items_per_page))
        count+=1
        time.sleep(randint(0, 5))
    
    return scraped_data



if __name__=="__main__":

    argparser = argparse.ArgumentParser()

    #argparser.add_argument('place',help = 'Location/ Address/ zip code')

    search_query_help = """Available search queries are:\n

                            Restaurants,\n

                            Breakfast & Brunch,\n

                            Coffee & Tea,\n

                            Delivery,\n

                            Reservations,\n
                            
                            Hospitals,\n
                            
                            Firedepartments, \n
                            
                            policedepartments, \n
                            
                            airports, \n
                            
                            collegeuniv, \n
                            
                            elementaryschools, \n
                            
                            highschools, \n
                            
                            drugstores, """

    argparser.add_argument('search_query',help = search_query_help)

    args = argparser.parse_args()

    #place = args.place

    search_query = args.search_query 
    place = "Miami"
    #search_query = "restaurants"
    
    '''Scraping data'''    
    scraped_data = parse(search_query)

    print ("Writing data to output file")

    csv.register_dialect('sc', delimiter=';')
   
    '''ab concatenate'''
    mode = "wb"
            
    with open("scraped_yelp_results_for_"+search_query+ "_%s.csv"%(place),mode) as fp:

        fieldnames= ['business_name','rank','review_count','categories','rating','address','longitude','latitude', 'price_range','url']

        writer = csv.DictWriter(fp,fieldnames=fieldnames,dialect='sc',extrasaction='ignore', delimiter = ';')
        
        writer.writeheader()

        for data in scraped_data:
            writer.writerow(data)