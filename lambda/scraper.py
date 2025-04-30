import requests
from bs4 import BeautifulSoup
from abc import ABC, abstractmethod

class BaseScraper(ABC):
    @abstractmethod
    def scrape_page(self, url):
        pass

    @abstractmethod
    def get_deals(self):
        pass

class OzBargain(BaseScraper):
    def scrape_page(self, url):
        response = requests.get(url)
        soup = BeautifulSoup(response.content, 'html.parser')
        deals = []

        for n_right in soup.find_all('div', class_='n-right'):
            # Get title
            h2 = n_right.find('h2', class_='title')
            if not h2 or not h2.has_attr('data-title'):
                continue
            title = h2['data-title']

            # Extract link
            relative_link = None
            link_tag = h2.find('a', href=True)
            if link_tag:
                relative_link = link_tag['href']
            deal_link = f'https://www.ozbargain.com.au{relative_link}' if relative_link else None

            # Find votes
            parent = n_right.parent
            n_left = parent.find('div', class_='n-left') if parent else None

            votes_plus = 0
            votes_minus = 0
            if n_left:
                voteup_span = n_left.find('span', class_='nvb voteup')
                votedown_span = n_left.find('span', class_='nvb votedown')
                if voteup_span and voteup_span.span:
                    try:
                        votes_plus = int(voteup_span.span.text.strip())
                    except Exception:
                        votes_plus = 0
                if votedown_span and votedown_span.span:
                    try:
                        votes_minus = int(votedown_span.span.text.strip())
                    except Exception:
                        votes_minus = 0

            deals.append({
                "title": title,
                "link": deal_link,
                "votes_plus": votes_plus,
                "votes_minus": votes_minus
            })

        return deals

    def get_deals(self):
        website_deals = []
        base_url = "https://www.ozbargain.com.au/deals?page="

        for page in range(0, 5):
            url = base_url + str(page)
            page_deals = self.scrape_page(url)
            website_deals.extend(page_deals)

        return website_deals

class FlightFinderAu(BaseScraper):
    def scrape_page(self, url):
        pass
    def get_deals(self):
        pass

def scrape_deals():
    scrapers = [OzBargain()]
    deals_results = []

    for scraper in scrapers:
        website_deals = scraper.get_deals()
        deals_results.extend(website_deals)

    return deals_results