import urllib
import HTMLParser
import re
import scrapy

urlText = []

class parserText(HTMLParser.HTMLParser):
    def handle_data(self, data):
        if data != '\n':
            urlText.append(data)

global url
url = "http://www.smzdm.com"
#parser = parserText()
#parser.feed(urllib.urlopen(url).read())
#parser.close()
#for item in urlText:
#    print item
#print len(urlText)
htmlText = urllib.urlopen(url).read()
print htmlText
for i in re.findall('''href=["'](.[^"']+)["']''', htmlText, re.I):
    print i

