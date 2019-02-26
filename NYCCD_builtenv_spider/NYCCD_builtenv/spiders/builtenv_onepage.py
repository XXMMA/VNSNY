# -*- coding: utf-8 -*-
import scrapy
from scrapy_splash import SplashRequest
# $ docker run -p 5023:5023 -p 8050:8050 -p 8051:8051 scrapinghub/splash
"""
                    function main(splash)
                        splash:set_user_agent(splash.args.ua)
                        assert(splash:go(splash.args.url))
                        while not splash:select('small.legend-dot-wrapper.cell.auto') do
                            splash:wait(0.5)
                        end
                        return {html=splash:html()}
                    end
"""

class Builtenv_onepageSpider(scrapy.Spider):
    print('===========================================================================================================')
    name = 'builtenv_onepage'
    pool = ['http://communityprofiles.planning.nyc.gov/manhattan/1/',
            'http://communityprofiles.planning.nyc.gov/manhattan/2/']
    start_urls = [pool[0]]
    num = 0
    facility_pool = ['Administration of Government','Core Infrastructure and Transportation',
                     'Education, Child Welfare, and Youth','Health and Human Services',
                     'Libraries and Cultural Programs','Parks, Gardens, and Historical Sites',
                     'Public Safety, Emergency Services, and Administration of Justice']
    #lua_script = 
    def start_requests(self):
        for url in self.start_urls:
            yield SplashRequest(
                url = url, 
                callback = self.parse,
                endpoint='render.html',
                args={'wait':3}
                       #'lua_source': self.lua_script,
                       #'ua': "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.106 Safari/537.36"}
                )

    def parse(self, response):
        filename = response.url[-2] + '.html'
        with open(filename,'wb') as f:
            f.write(response.body)
        zoning_ = response.xpath('//strong[text() = "Zoning "]/ancestor::h4/following-sibling::div[@class = "callout"][1]//*[contains(.," | ")]/text()').re('(.*)\s\|\s(.*)')
        land_use_ = response.xpath('//strong[text() = "Land Use "]/ancestor::h4/following-sibling::div[@class = "callout"][1]//*[contains(.," | ")]/text()').re('(.*)\s\|\s(.*)')
        board = {}
        zoning = {}
        land_use = {}
        facilities = {}
        for i in range(int(len(zoning_) * 0.5 )):
            zoning[zoning_[2 * i]] = float(zoning_[2 * i + 1].strip('%'))/100

        for i in range(int(len(land_use_) * 0.5 )):
            land_use[land_use_[2 * i]] = float(land_use_[2 * i + 1].strip('%'))/100

        for facility in self.facility_pool:
            query = '//small[text() = ' + '"' + facility + '"' + ']/preceding-sibling::span/strong/text()'
            facilities[facility] = int(response.xpath(query).get())
        board['borocd'] = 209
        board['zoning'] = zoning
        board['land_use'] = land_use
        board['facilities'] = facilities
        yield board

        self.num = self.num + 1
        if self.num < len(self.pool):
            print(self.pool[self.num])
            print('wait!!!!!!!!!!!!!!!!!!!!!!!!!!!!!one more')
            yield SplashRequest(
                url = self.pool[self.num], 
                callback = self.parse,
                endpoint='render.html',
                args={'wait':3}
                )
        
        

