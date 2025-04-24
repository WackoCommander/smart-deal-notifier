import requests
from bs4 import BeautifulSoup
from abc import ABC, abstractmethod

class BaseScraper(ABC):
    @abstractmethod
    def scrape_page(self, url):
        """
        Should return a list of dicts with;
        - id: uuid of title
        - title: str
        - price: str 
        - url: str
        Example:
        [
            { 
                "id": "123",
                "title": "Product Title",
                "price": "19.99",
                "url": "https://..."
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

