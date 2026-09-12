'use strict';
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const {join} = require('node:path');
const {normalize, prepare, search, snippet} = require('../assets/search.js');
const data = JSON.parse(readFileSync(join(__dirname,'../docs/search-index.json'),'utf8'));
const records = prepare(data.records);
const urls = query => search(records,query).map(hit=>hit.record.url);
assert.ok(urls('CMP29').length > 0);
for (const query of ['MP29','MP 29','cmp-29','MP–29','CMP−29']) {
  assert.deepEqual(urls(query), urls('CMP29'), query);
}
assert.ok(urls('CMP29 2027').some(url=>url.startsWith('tac-advice-2027-2028.html#')));
assert.ok(urls('CPUE').some(url=>url.startsWith('assessment/SC14.html#')));
assert.ok(urls('recruit').length > 0);
assert.equal(urls('zzzxxyynonexistent').length, 0);
assert.equal(urls('x').length, 0);
assert.equal(urls('!@#$%').length, 0);
assert.equal(normalize('Péru'), 'peru');
const text = 'Unrelated introduction. '.repeat(30) + 'MP29 applies the candidate rule to the index.';
assert.match(snippet(text,'CMP29'), /MP29 applies/);
assert.equal(snippet(text,'CMP29'),snippet(text,'MP 29'));
const fixture = prepare([{title:'Survey',heading:'Index',url:'survey.html',text:'Peru CPUE observations'}]);
assert.equal(search(fixture,'Peru acoustic').length,0);
assert.equal(search(fixture,'Peru CPUE').length,1);
assert.equal(new Set(urls('TAC')).size, urls('TAC').length);
console.log('PASS: CMP aliases, excerpts, TAC/assessment retrieval, prefix and multiple-term matching, empty results and deduplication');
