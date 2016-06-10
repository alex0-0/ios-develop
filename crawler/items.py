from scrapy.item import Item, Field

class myItem(Item):
    title = Field()
    #description = Field()
    url = Field()
