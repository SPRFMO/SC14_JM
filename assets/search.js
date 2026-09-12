(function (root) {
  'use strict';
  function normalize(text) {
    return String(text).normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLowerCase()
      .replace(/[\u2010-\u2015\u2212]/g, '-')
      .replace(/\b(?:cmp|mp)[\s_-]*(\d+)\b/g, 'cmp$1')
      .replace(/[^a-z0-9]+/g, ' ').trim();
  }
  function prepare(records) {
    return records.map(record => ({...record, titleKey: normalize(record.title),
      headingKey: normalize(record.heading), textKey: normalize(record.text),
      words: new Set(normalize(`${record.title} ${record.heading} ${record.text}`).split(' '))}));
  }
  function search(records, query) {
    const phrase = normalize(query);
    if (phrase.length < 2) return [];
    const terms = [...new Set(phrase.split(' '))];
    const hits = [];
    for (const record of records) {
      const words = [...record.words];
      if (!terms.every(term => record.words.has(term) || (term.length >= 3 && words.some(word => word.startsWith(term))))) continue;
      const score = (record.titleKey.includes(phrase) ? 60 : 0) + (record.headingKey.includes(phrase) ? 45 : 0)
        + terms.reduce((sum, term) => sum + (record.titleKey.includes(term) ? 15 : 0)
          + (record.headingKey.includes(term) ? 10 : 0) + (record.textKey.includes(term) ? 2 : 0), 0);
      hits.push({record, score});
    }
    hits.sort((a,b) => b.score-a.score || a.record.title.localeCompare(b.record.title));
    // Keep one useful passage per section, rather than duplicate results for long tables.
    const seen = new Set();
    return hits.filter(hit => {if (seen.has(hit.record.url)) return false; seen.add(hit.record.url); return true;});
  }
  function snippet(text, query) {
    const terms = normalize(query).split(' ').filter(Boolean);
    const matches = terms.map(term => {
      const cmp = /^cmp(\d+)$/.exec(term);
      const pattern = cmp ? `\\b(?:cmp|mp)[\\s_\\-\\u2010-\\u2015\\u2212]*${cmp[1]}\\b` : term;
      return text.search(new RegExp(pattern, 'i'));
    }).filter(i=>i>=0);
    let start = matches.length ? Math.max(0, Math.min(...matches)-75) : 0;
    if (start) {const space = text.indexOf(' ', start);if(space>=0)start=space+1;}
    return (start ? '…' : '') + text.slice(start, start+260) + (text.length>start+260?'…':'');
  }
  const api = {normalize, prepare, search, snippet};
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  root.WikiSearch = api;
  if (typeof document === 'undefined') return;
  const form = document.getElementById('contents-search');
  if (!form) return;
  const input = document.getElementById('search-query');
  const status = document.getElementById('search-status');
  const results = document.getElementById('search-results');
  const base = new URL('./', document.currentScript.src);
  let records = null;
  let loading = null;
  let timer;
  let request = 0;
  async function run(updateUrl) {
    const current = ++request;
    const query = input.value.trim();
    results.replaceChildren();
    if (updateUrl) {
      const url = new URL(location.href);
      if (query) url.searchParams.set('q',query); else url.searchParams.delete('q');
      history.replaceState(null,'',url);
    }
    if (normalize(query).length < 2) {status.textContent='Enter at least two characters to search.'; return;}
    status.textContent='Searching…';
    try {
      if (!loading) loading = fetch(new URL('search-index.json',base)).then(response=>{
        if(!response.ok)throw new Error('Search index unavailable');return response.json();
      }).then(data=>{records=prepare(data.records);return records;}).catch(error=>{loading=null;throw error;});
      await loading;
      if (current !== request) return;
      const hits = search(records,query);
      status.textContent = hits.length ? `${hits.length} result${hits.length===1?'':'s'}${hits.length>40?' — showing the first 40':''}.`
        : 'No results. Try fewer words or a different term.';
      for (const {record} of hits.slice(0,40)) {
        const item=document.createElement('li');
        const link=document.createElement('a');
        link.href=new URL(record.url,base).href;
        link.textContent=record.heading && record.heading!==record.title ? `${record.title} — ${record.heading}` : record.title;
        const excerpt=document.createElement('p');excerpt.textContent=snippet(record.text,query);
        const source=document.createElement('small');source.textContent=record.url.split('#')[0];
        item.append(link,excerpt,source);results.append(item);
      }
    } catch(error) {
      if(current===request)status.textContent='Search could not load. Please check your connection and try again.';
    }
  }
  input.value=new URL(location.href).searchParams.get('q') || '';
  form.addEventListener('submit',event=>{event.preventDefault();clearTimeout(timer);run(true);});
  input.addEventListener('input',()=>{clearTimeout(timer);timer=setTimeout(()=>run(true),150);});
  input.addEventListener('keydown',event=>{if(event.key==='Escape'){input.value='';clearTimeout(timer);run(true);}});
  root.addEventListener('popstate',()=>{input.value=new URL(location.href).searchParams.get('q') || '';run(false);});
  run(false);
})(typeof globalThis !== 'undefined' ? globalThis : this);
