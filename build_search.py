"""Create a section-level search index from the wiki's published HTML."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import quote
import json
import re


class SearchText(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.main = False
        self.skip = 0
        self.stack = []
        self.heading = None
        self.heading_text = []
        self.section_title = ''
        self.anchor = ''
        self.text = []
        self.sections = []
        self.title = []
        self.in_title = False
        self.has_main = False

    def flush(self):
        text = re.sub(r'\s+', ' ', ' '.join(self.text)).strip()
        if text:
            self.sections.append({'heading': self.section_title, 'anchor': self.anchor, 'text': text})
        self.text = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == 'title':
            self.in_title = True
        if tag == 'main':
            self.main = self.has_main = True
        if tag in ('section', 'div'):
            self.stack.append((tag, a.get('id', '')))
        if tag in ('script', 'style', 'nav', 'aside', 'footer', 'button'):
            self.skip += 1
        if self.main and not self.skip:
            if tag in ('h1', 'h2', 'h3'):
                self.flush()
                self.heading = tag
                self.heading_text = []
                self.anchor = a.get('id') or next((i for t, i in reversed(self.stack) if t == 'section' and i), '')
            elif tag == 'img' and a.get('alt'):
                self.text.append(a['alt'])
            elif tag in ('p', 'li', 'tr', 'td', 'th', 'br'):
                self.text.append(' ')

    def handle_endtag(self, tag):
        if tag == 'title':
            self.in_title = False
        if self.main and not self.skip and tag == self.heading:
            self.section_title = re.sub(r'\s+', ' ', ''.join(self.heading_text)).strip()
            self.text.append(self.section_title)
            self.heading = None
        if tag == 'main':
            self.flush()
            self.main = False
        if tag in ('script', 'style', 'nav', 'aside', 'footer', 'button'):
            self.skip = max(0, self.skip-1)
        if tag in ('section', 'div'):
            for i in range(len(self.stack)-1, -1, -1):
                if self.stack[i][0] == tag:
                    del self.stack[i:]
                    break

    def handle_data(self, data):
        if self.in_title:
            self.title.append(data)
        if self.main and not self.skip:
            if self.heading:
                self.heading_text.append(data)
            else:
                self.text.append(data)


def build_index(out):
    out = Path(out)
    records = []
    documents = []
    excluded = {'search.html', 'kobe-100-trajectories-2007-2026.html'}
    labels = {
        'assessment/SC14.html': 'SC14 assessment report',
        'assessment/loo.html': 'Assessment index sensitivities: LOI and LOO',
    }
    for file in sorted(out.rglob('*.html')):
        relative = file.relative_to(out).as_posix()
        if file.name in excluded or any(p == 'site_libs' or p.endswith('_files') for p in file.parts):
            continue
        parser = SearchText()
        parser.feed(file.read_text(encoding='utf-8'))
        parser.flush()
        if not parser.has_main:
            continue
        title = labels.get(relative, ''.join(parser.title).split(' | ')[0].strip())
        document_count = 0
        for section in parser.sections:
            if not section['heading'] and section['text'] == 'Research findings, proposals and agreed decisions are distinguished throughout this guide.':
                continue
            # Bound each passage so queries return a useful excerpt even in long reports.
            words = section['text'].split()
            for start in range(0, len(words), 350):
                body = ' '.join(words[start:start+400])
                url = quote(relative, safe='/.-_')
                if section['anchor']:
                    url += '#' + quote(section['anchor'], safe='-_.:')
                records.append({'title': title, 'heading': section['heading'] if section['anchor'] else '', 'url': url, 'text': body})
                document_count += 1
        documents.append({'url': relative, 'title': title, 'passages': document_count})
    data = {'version': 1, 'documents': documents, 'records': records}
    (out/'search-index.json').write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')) + '\n')
    return data


if __name__ == '__main__':
    index = build_index(Path(__file__).resolve().parent/'docs')
    print(f"Indexed {len(index['documents'])} documents and {len(index['records'])} passages")
