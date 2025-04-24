import requests
from bs4 import BeautifulSoup
from abc import ABC, abstractmethod
import uuid
import hashlib

class BaseScraper(ABC):
    @abstractmethod
    def scrape_page(self, url):
        """
        Should return a list of deals for that particular page;
        - deal - article description e.g. "iPad costs 14.99 at Officeworks"
        """
        pass

    @abstractmethod
    def get_deals(self):
        """
        This function should manage the function of scraping multiple pages.
        Should return one array of deals
        """
        pass



class OzBargain(BaseScraper):
    def scrape_page(self, url):
        return results

    def get_deals(self, url):
        return deals


def scrape_deals():
    # Instantiate scrapers
    scrapers = [OzBargain()]

    for scraper in scrapers:
        deals = scraper.get_deals()

    return deals

