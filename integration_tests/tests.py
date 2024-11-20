import os
from unittest import TestCase

import requests

BASE_URL = os.environ.get("SIMPSONS_BASE_URL", "http://localhost:4567")


class DefaultTest(TestCase):
    def test_base(self):
        url = f"{BASE_URL}"
        res = requests.get(url)
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.text, "Welcome to the Simpson household")


class HomerTest(TestCase):
    def test_homer_message(self):
        url = f"{BASE_URL}/homer"
        res = requests.get(url)
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.text, "I hope you brought donuts")

    def test_homer_good_gift(self):
        url = f"{BASE_URL}/homer"
        res = requests.post(url, json={"gift": "donut"})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.text, "Woohoo")

    def test_homer_bad_gift(self):
        url = f"{BASE_URL}/homer"
        res = requests.post(url, json={"gift": "celery"})
        self.assertEqual(res.status_code, 400)
        self.assertEqual(res.text, "D'oh")


class LisaTest(TestCase):
    def test_lisa_message(self):
        url = f"{BASE_URL}/lisa"
        res = requests.get(url)
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.text, "The baritone sax is the best sax")

    def test_lisa_good_gift(self):
        url = f"{BASE_URL}/lisa"
        res = requests.post(url, json={"gift": "book"})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.text, "I love it")

    def test_lisa_great_gift(self):
        url = f"{BASE_URL}/lisa"
        res = requests.post(url, json={"gift": "saxaphone"})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.text, "I REALLY love it")

    def test_lisa_bad_gift(self):
        url = f"{BASE_URL}/lisa"
        res = requests.post(url, json={"gift": "video_game"})
        self.assertEqual(res.status_code, 400)
        self.assertEqual(res.text, "I hate it")

    def test_lisa_horrible_gift(self):
        url = f"{BASE_URL}/lisa"
        res = requests.post(url, json={"gift": "skateboard"})
        self.assertEqual(res.status_code, 400)
        self.assertEqual(res.text, "I REALLY hate it")
