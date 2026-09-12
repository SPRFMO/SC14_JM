"""Check search coverage, destinations and navigation against the built site."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from build_search import SearchText


class IDs(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = set()

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])


index = json.loads((ROOT/'docs/search-index.json').read_text())
documents = {d['url'] for d in index['documents']}
assert 'tac-advice-2027-2028.html' in documents
assert 'assessment/SC14.html' in documents
assert 'assessment/loo.html' in documents
assert 'search.html' not in documents
assert not any('annex/' in d or 'kobe-100-trajectories' in d for d in documents)
assert len(documents) == len(index['documents'])
ids = {}
for document in documents:
    parser = IDs()
    parser.feed((ROOT/'docs'/document).read_text())
    ids[document] = parser.ids
for record in index['records']:
    destination = urlsplit(record['url'])
    assert destination.path in documents, record['url']
    assert not destination.fragment or unquote(destination.fragment) in ids[destination.path], record['url']
    assert destination.fragment != 'quarto-content', record['url']
    assert record['text'].strip()
    assert 'Search wiki' not in record['text']
for source in (ROOT/'content').glob('*.md'):
    rendered = (ROOT/'docs'/f'{source.stem}.html').read_text()
    assert 'class="wiki-search" action="search.html"' in rendered, source
    assert '<script defer src="search.js"></script>' in rendered, source
for asset in ('search.js', 'search.css'):
    assert (ROOT/'assets'/asset).read_bytes() == (ROOT/'docs'/asset).read_bytes(), asset
fixture = SearchText()
fixture.feed('<title>Example</title><nav>Exclude nav</nav><main><h1 id="top">Fish</h1><p>Visible text</p><script>Exclude script</script><section id="survey"><h2>Survey</h2><p>CPUE</p></section><footer>Exclude footer</footer></main>')
assert [s['anchor'] for s in fixture.sections] == ['top', 'survey']
assert all('Exclude' not in s['text'] for s in fixture.sections)
print(f"PASS: {len(documents)} documents, {len(index['records'])} passages, all destinations and wiki search forms checked")
