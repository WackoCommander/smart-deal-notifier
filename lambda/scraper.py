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
        response = requests.get(url)
        soup = BeautifulSoup(response.content, 'html.parser')
        titles = [tag['data-title'] for tag in soup.find_all(attrs={'data-title': True})]

        return titles

    def get_deals(self):
        website_deals = []
        base_url = "https://www.ozbargain.com.au/deals?page="

        for page in range(0,5):
            url = base_url + str(page)
            page_deals = self.scrape_page(url)
            website_deals.extend(page_deals)

        return website_deals


def scrape_deals():
    # Instantiate scrapers
    scrapers = [OzBargain()]
    deals_titles = []

    for scraper in scrapers:
        website_deals = scraper.get_deals()
        deals_titles.extend(website_deals)

    
    """
    deals_with_id = []
    for title in deals_titles:
        hex_string = hashlib.md5(str(title).encode("UTF-8"))
        deal_id = uuid.UUID(hex=hex_string)
        deal_with_id = {
                "id": deal_id,
                "title": title
                }
    """
    return deals_titles

