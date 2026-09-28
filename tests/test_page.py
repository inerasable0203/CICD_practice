from html.parser import HTMLParser
from pathlib import Path
import unittest


class PageParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.lang = None
        self.ids = set()
        self.title = ""
        self.in_title = False

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "html":
            self.lang = attrs.get("lang")
        if "id" in attrs:
            self.ids.add(attrs["id"])
        if tag == "title":
            self.in_title = True

    def handle_endtag(self, tag):
        if tag == "title":
            self.in_title = False

    def handle_data(self, data):
        if self.in_title:
            self.title += data


class PageTest(unittest.TestCase):
    def test_page_has_counter_controls(self):
        page = Path(__file__).resolve().parents[1] / "index.html"
        parser = PageParser()
        parser.feed(page.read_text(encoding="utf-8"))
        self.assertEqual(parser.lang, "ko")
        self.assertEqual(parser.title, "CI/CD 실습 카운터-New branch")
        self.assertTrue({"count", "increase", "reset"} <= parser.ids)


if __name__ == "__main__":
    unittest.main()
