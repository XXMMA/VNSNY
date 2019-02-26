# -*- coding: utf-8 -*-
import scrapy
from scrapy_splash import SplashRequest
# $ docker run -p 5023:5023 -p 8050:8050 -p 8051:8051 scrapinghub/splash

class BuiltenvSpider(scrapy.Spider):
    name = 'builtenv'
    url_pool = []
    num_page_fin = 0
    facility_pool = ['Administration of Government','Core Infrastructure and Transportation',
                     'Education, Child Welfare, and Youth','Health and Human Services',
                     'Libraries and Cultural Programs','Parks, Gardens, and Historical Sites',
                     'Public Safety, Emergency Services, and Administration of Justice']
    boros  = [{'borough':'manhattan','num':12},
              {'borough':'bronx','num':12},
              {'borough':'brooklyn','num':18},
              {'borough':'queens','num':14},
              {'borough':'staten-island','num':3}]
    borosCD = {'manhattan':1,'bronx':2,'brooklyn':3,'queens':4,'staten-island':5}
    for boro in boros:
        for i in range(boro['num']):
            url_pool.append('http://communityprofiles.planning.nyc.gov/%s/%d/' % (boro['borough'], i + 1))

    start_urls = [url_pool[0]]
    wait_time = 5
    retry = 0
    def start_requests(self):
        for url in self.start_urls:
            yield SplashRequest(
                url = url, 
                callback = self.parse,
                endpoint='render.html',
                args={'wait': self.wait_time}
            )

    def parse(self, response):
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
        board['borocd'] = self.borosCD[response.url.split('/')[-3]] * 100 + int(response.url.split('/')[-2])
        board['zoning'] = zoning
        board['land_use'] = land_use
        board['facilities'] = facilities
        if zoning != {} and land_use != {} and facilities != {}:
            yield board

            self.num_page_fin = self.num_page_fin + 1
            self.wait_time = 5
            retry = 0
            if self.num_page_fin < len(self.url_pool):
                yield SplashRequest(
                    url = self.url_pool[self.num_page_fin],
                    callback = self.parse,
                    endpoint = 'render.html',
                    args = {'wait':self.wait_time}
                    )
        else:
            retry = retry + 1
            self.wait_time = 5 + 2 ** retry
            yield SplashRequest(
                    url = response.url,
                    callback = self.parse,
                    endpoint = 'render.html',
                    args = {'wait':self.wait_time}
                )

        

