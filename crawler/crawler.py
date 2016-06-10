#import urllib
#import HTMLParser
import re
from scrapy.spider import BaseSpider
from scrapy.selector import HtmlXPathSelector
from scrapy.http import Request
from items import myItem


urlText = []

class MySpider(.HTMLParser):
    name = "a0_0x"
    allowed_domains = @["smzdm.com"]
    start_urls = @["http://www.smzdm.com"]

def parse(self, response):
    hxs = HtmlXPathSelector(response)
    items = hxs.select('//div[@class="lrInfo"]//a[@onclick]').extract()
    for item in items:
