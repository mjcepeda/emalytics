import scrapy
#import csv
#import sys
import re
from realtor1.items import RealtorItem

#from scrapy.spider import BaseSpider
#from scrapy.selector import HtmlXPathSelector
#from realtor.items import RealtorItem
class RealtorSpider(scrapy.Spider):
	rotate_user_agent = True
	name = "realtor1"
	allowed_domains = ["realtor.com"]
	start_urls = [
					'C://Users//Ash//realtor1/realtor2.txt'
					]
					
	
	
	def parse(self, response):
		#hxs = HtmlXPathSelector(response)
		#sites = hxs.select('//div/li/div/a/@href')
		sites = response.xpath('.//section[@class="listing-header"][@id="listing-header"]/div[@class="listing-header-main"]/div[contains(@class, "header-main-info")]')
		xmeta = response.xpath('.//head')
		xtype = response.xpath('.//div[contains(@class, "listing-section-details")]')
		#p = re.compile('\$([0-9]*[,][0-9]*)*')
		#bed = re.compile('[0-9] (bed)')
		#bath = re.compile('[0-9] (bath)')
		#sqft = re.compile('(([0-9]*,[0-9]*)* Sq. Ft.)')
		#print p
		items =  []
		for site in sites: 
			
			p = []
			q = []
			r = []
			s = []
			t = []
			item = RealtorItem()
			#desc = site.xpath('meta[@name="description"]/@content').extract()
			item['price'] = site.xpath('//div/div/div/div/div/span[contains(@itemprop, "price")]/@content').extract()
			if site.xpath('//div/div/div/ul/li[contains(@data-label, "baths")]/div/span/text()').extract() :
				p = site.xpath('//div/div/div/ul/li[contains(@data-label, "baths")]/div/span/text()').extract()
				item['bath'] = p[0]
				item['hlfbath'] = p[1]
			else :
				q = site.xpath('//div/div/div/ul/li[contains(@data-label, "bath")]/span/text()').extract()
				item['bath'] = q[0]
			if 	site.xpath('//div/div/div/ul/li[contains(@data-label, "sqft")]/span/text()').extract():
				s = site.xpath('//div/div/div/ul/li[contains(@data-label, "sqft")]/span/text()').extract()
				item['sqft'] = s[0]
			if site.xpath('//div/div/div/ul/li[contains(@data-label, "lotsize")]/span/text()').extract():
				t = site.xpath('//div/div/div/ul/li[contains(@data-label, "lotsize")]/span/text()').extract()
				item['lotsize'] = t[0]
			#item['address'] = site.xpath
			r = site.xpath('//div/div/div/ul/li[contains(@data-label, "bed")]/span/text()').extract()
			item['bed'] = r[0]
			item['address'] = xmeta.xpath('meta[contains(@property, "address")]/@content').extract()
			item['zip'] = xmeta.xpath('meta[contains(@property, "postal")]/@content').extract()
			item['lati'] =xmeta.xpath('meta[contains(@property, "latitude")]/@content').extract()
			item['longi'] = xmeta.xpath('meta[contains(@property, "longitude")]/@content').extract()
			
			if xtype.xpath('//li[contains(@data-label, "property-type")]/div[contains(@class, "key-fact-data ellipsis")]/text()').extract():
				u = xtype.xpath('//li[contains(@data-label, "property-type")]/div[contains(@class, "key-fact-data ellipsis")]/text()').extract()
				item['type'] = u[0]
			items.append(item)
		return items