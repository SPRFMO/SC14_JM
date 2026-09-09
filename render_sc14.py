#!/usr/bin/env python3
"""Render current jjm outputs and stage the report in this wiki. Never pushes."""
import argparse
import shutil
import subprocess
import tempfile
from pathlib import Path
from sync_sc14 import ROOT, synchronize

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--jjm', required=True, type=Path, help='Local SPRFMO/jjm checkout')
a = p.parse_args()
repo = a.jjm.resolve(strict=True)
source = repo / 'doc/SC14.qmd'
if not source.is_file(): p.error('Missing doc/SC14.qmd; include doc in the sparse checkout')
# A standalone copy avoids importing jjm website navigation into the wiki.
# The report root still resolves to the original assessment outputs.
with tempfile.TemporaryDirectory(prefix='sc14-wiki-') as directory:
    stage = Path(directory)
    doc = stage / 'doc'
    doc.mkdir()
    shutil.copy2(source, doc / 'SC14.qmd')
    (stage / 'assessment').symlink_to(repo / 'assessment', target_is_directory=True)
    for name in ('_includes', 'annex'):
        (doc / name).symlink_to(repo / 'doc' / name, target_is_directory=True)
    subprocess.run(['quarto', 'render', str(doc / 'SC14.qmd'), '--to', 'html'], check=True)
    synchronize(doc / 'SC14.html', source_repo=repo)
subprocess.run(['python3', str(ROOT / 'build.py')], check=True)
print('Rendered and synchronized locally. Review the wiki changes before committing and publishing.')
