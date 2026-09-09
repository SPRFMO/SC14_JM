#!/usr/bin/env python3
"""Stage a self-contained SC14 render in the wiki, without publishing it."""
import argparse
import base64
import hashlib
import json
import re
import subprocess
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit, unquote

ROOT = Path(__file__).resolve().parent
START = '<!-- sc14-assessment:start -->'
END = '<!-- sc14-assessment:end -->'

class References(HTMLParser):
    def __init__(self):
        super().__init__()
        self.local = []
        self.title = False
        self.title_text = ''
        self.anchor = None
        self.embedded = {}
    def handle_starttag(self, tag, attrs):
        d = dict(attrs)
        if tag == 'a': self.anchor = d.get('href')
        if tag == 'img' and self.anchor and d.get('src', '').startswith('data:image/'):
            self.embedded[self.anchor] = d['src']
        if tag == 'title': self.title = True
        keys = ['src', 'poster', 'data']
        if tag in ('link', 'a'): keys.append('href')
        for key in keys:
            value = d.get(key, '')
            if value and not value.startswith(('#', '//')) and not urlsplit(value).scheme:
                self.local.append(value)
        if d.get('srcset') and not d['srcset'].startswith('data:'):
            self.local.append('srcset: ' + d['srcset'])
    def handle_endtag(self, tag):
        if tag == 'title': self.title = False
        if tag == 'a': self.anchor = None
    def handle_data(self, value):
        if self.title: self.title_text += value

def synchronize(source, root=ROOT, source_repo=None):
    source = source.resolve(strict=True)
    payload = source.read_bytes()
    text = payload.decode('utf-8')
    parser = References()
    parser.feed(text)
    if '<html' not in text.lower() or 'SC14' not in parser.title_text.upper():
        raise ValueError('Expected a rendered HTML document with SC14 in its title')
    # Reject relative CSS resources as well as HTML references. Nothing from the
    # assessment directory is copied implicitly into the public wiki.
    for value in re.findall(r'url\(\s*[\'"]?([^\)\'"\s]+)', text):
        if not value.startswith(('#', '//')) and not urlsplit(value).scheme:
            parser.local.append(value)
    assets = {}
    for url in sorted(set(parser.local)):
        relative = Path(unquote(urlsplit(url).path))
        # Quarto embeds display images but retains local lightbox download links.
        # Copy only those explicit figure files, never a whole model directory.
        if (relative.is_absolute() or '..' in relative.parts or
            relative.parts[:2] != ('SC14_files', 'figure-html') or
            relative.suffix.lower() not in ('.png', '.jpg', '.jpeg', '.svg', '.webp')):
            raise ValueError('Unembedded or local document dependency: ' + url)
        asset = (source.parent / relative).resolve()
        if not asset.is_relative_to(source.parent):
            raise ValueError('Figure resolves outside the render directory: ' + url)
        if asset.is_file():
            value = asset.read_bytes()
        elif url in parser.embedded:
            header, encoded = parser.embedded[url].split(',', 1)
            if not header.endswith(';base64'): raise ValueError('Expected base64 figure: ' + url)
            value = base64.b64decode(encoded, validate=True)
        else:
            raise ValueError('Missing linked figure: ' + url)
        assets[relative.as_posix()] = value
    output = root / 'docs/assessment/SC14.html'
    stamp = root / 'docs/assessment/sync.json'
    digest = hashlib.sha256(payload).hexdigest()
    block = (START + '\n## Current SC14 assessment\n\n'
             '[Read the current SC14 assessment report](assessment/SC14.html).\n\n'
             'This working assessment presents model results for review. Its draft or proposed-model '
             'labels remain as stated in the report. It does not by itself establish agreed '
             'Scientific Committee advice.\n\n'
             '[Report synchronization record](assessment/sync.json).\n' + END)
    page = root / 'content/assessments.md'
    original = page.read_text()
    if START in original:
        revised = re.sub(re.escape(START) + r'.*?' + re.escape(END), lambda _: block, original, flags=re.S)
    else:
        revised = original.replace('## What the research has done', block + '\n\n## What the research has done', 1)
        if revised == original: raise ValueError('Assessment page insertion point not found')
    if (output.exists() and output.read_bytes() == payload and revised == original and
        all((output.parent / key).is_file() and (output.parent / key).read_bytes() == value
            for key, value in assets.items())):
        return False
    def git(*args):
        r = subprocess.run(['git', '-C', str(source_repo or source.parent), *args], capture_output=True, text=True)
        return r.stdout.strip() if r.returncode == 0 else None
    record = {'source_repository': 'SPRFMO/jjm', 'source_filename': source.name,
              'source_revision': git('rev-parse', 'HEAD'),
              'source_worktree_dirty': bool(git('status', '--porcelain', '--untracked-files=no')),
              'sha256': digest, 'title': parser.title_text,
              'assets': {name: hashlib.sha256(value).hexdigest() for name, value in assets.items()},
              'synchronized_utc': datetime.now(timezone.utc).isoformat(),
              'note': 'Exact rendered file copy. Git revision alone does not identify untracked render contents.'}
    output.parent.mkdir(parents=True, exist_ok=True)
    for name, value in assets.items():
        target = output.parent / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(value)
    temporary = output.with_suffix('.html.tmp')
    temporary.write_bytes(payload)
    temporary.replace(output)
    stamp.write_text(json.dumps(record, indent=2) + '\n')
    page.write_text(revised)
    return True

if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source', required=True, type=Path, help='Exact current self-contained SC14.html render')
    p.add_argument('--source-repo', type=Path, help='jjm checkout, required for provenance of a staged render')
    args = p.parse_args()
    try:
        changed = synchronize(args.source, source_repo=args.source_repo)
    except (OSError, ValueError) as e:
        p.exit(1, str(e) + '\n')
    print('SC14 report synchronized. Run python3 build.py and review before publishing.' if changed else 'SC14 is already synchronized.')
