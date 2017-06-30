from scrapy.item import Item, Field
class RealtorItem(Item):
	price = Field()
	bed = Field()
	bath = Field()
	hlfbath = Field()
	lotsize = Field()
	type = Field()
	sqft = Field()
	address = Field()
	zip = Field()
	lati = Field()
	longi = Field()