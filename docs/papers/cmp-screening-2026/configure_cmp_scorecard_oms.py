from pathlib import Path
import json,re
root=Path('output/cmp-working-paper-2026')
data=json.loads((root/'scorecards-all-oms.json').read_text())
for name in ['all','shortlist']:
 p=root/f'scorecard-{name}.qmd'
 s=Path('doc/application/scorecard-best-relative.qmd').read_text()
 s=s.replace('page-layout: full','format:\n  html:\n    embed-resources: true\n    theme: cosmo')
 s=s.replace('title: "Interactive CMP scorecard: best-relative weighting"',f'title: "Best-relative scorecard: {"all CMPs" if name=="all" else "retained CMPs"} and fixed-catch reference"')
 s=s.replace('This browser-based explorer reproduces','[Return to the working paper](cmp-screening-working-paper.html).\n\nThis browser-based explorer reproduces',1)
 s=s.replace('(scorecard.qmd)','(https://sprfmo.github.io/jmMSE26/application/scorecard.html)')
 s=s.replace('<option value="equal">','<option value="equal" selected>').replace('<option value="dispersion" selected>','<option value="dispersion">')
 s=s.replace('["SB0red","PC270"]','["SB0red","PC270","SSBbelow8dB0","CatchDrop20"]')
 s=s.replace('"P(Kobe red)"\n  ]','"P(Kobe red)", "SSB <8% dynamic B0 (%)"\n  ]')
 s=s.replace('"Mean catch reduction"]','"Mean catch reduction", "P(catch < 270 kt)", "Advice reductions >19% (%)"]')
 s=s.replace('<style>','For a lower-is-better indicator with a best value of zero, zero-valued CMPs score 100 and positive values score zero. Advice reductions greater than 19% pool all valid annual HCR-advice comparisons across all 500 iterations. The first advice is compared with the saved HCR initialization (the constant target for fixed catch). No biomass or near-20% exclusions apply. In two-stock OMs this is advice for the managed Southern stock, shared across component views.\n\n<style>',1)
 selected=None if name=='all' else {'HS-20 (MP43)','HS-30 (MP47)','PR-20 (MP44)','Fixed catch (1,525 kt)'}
 rows=[r for r in data if selected is None or r['mp'] in selected]
 # Start from the unchanged general explorer for repeatable generation.
 fetch_start=s.index('  let rows;'); fetch_end=s.index('\n  const cmps',fetch_start)
 s=s[:fetch_start]+'  const rows = [];\n'+s[fetch_end:]
 s=re.sub(r'  (?:const rows|const allRows) = .*?;\n(?=\n?  (?:const cmps|let rows))','  const allRows = '+json.dumps(rows,separators=(',',':'))+';\n',s,flags=re.S)
 start=s.index('  const cmps =') if '  const cmps =' in s else s.index('  let rows =')
 end=s.index('\n  function selectedValues',start)
 s=s[:start]+'''  let rows = [], cmps = [], metrics = [];
  const cmpSelection = new Set(allRows.map(d=>d.mp));
  const omValues = unique(allRows.map(d=>d.om_code));
  const omSelect = document.getElementById("om-select");
  const componentSelect = document.getElementById("component-select");
  omSelect.innerHTML=omValues.map(code=>`<option value="${code}">${escapeHtml(allRows.find(d=>d.om_code===code).om_label)}</option>`).join("");
  function optionList(containerId, values, selected, prefix) {
    document.getElementById(containerId).innerHTML = values.map((value,i)=>
      `<label><input type="checkbox" id="${prefix}-${i}" value="${escapeHtml(value)}" ${selected.includes(value)?"checked":""}> ${escapeHtml(value)}</label>`).join("");
  }
  function refreshMetricOptions() {
    const previous=selectedValues("metric-options");
    const selected=selectedValues("cmp-options");
    metrics=unique(rows.map(d=>d.metric)).filter(metric=>selected.every(mp=>rows.some(d=>d.mp===mp&&d.metric===metric)));
    const defaults=unique(rows.filter(d=>d.include).map(d=>d.metric));
    const retained=previous.filter(m=>metrics.includes(m));
    optionList("metric-options",metrics,retained.length?retained:defaults,"metric");
  }
  function selectComponent() {
    rows=allRows.filter(d=>d.om_code===omSelect.value&&d.component===componentSelect.value);
    cmps=unique(rows.map(d=>d.mp));
    optionList("cmp-options",cmps,cmps.filter(mp=>cmpSelection.has(mp)),"cmp");
    refreshMetricOptions();
    const fixed=rows.some(d=>d.mp.startsWith("Fixed catch"));
    const component=componentSelect.options[componentSelect.selectedIndex].text;
    document.getElementById("om-context").textContent=`${rows[0].om_label} · ${component} · 500 simulations per CMP · 2041–2050 (advice reductions: all annual comparisons, advice years 2025–2049, applied 2026–2050; optional mean catch reduction: 2026–2050). Scores are relative within this selection; OMs are not pooled. `+
      (componentSelect.value==='CJM'?"":"The 270 kt whole-stock catch threshold is omitted for stock components. ")+
      (fixed?"Fixed catch is available here as the supplied reference benchmark; it has different recruitment deviations and stored MSY values. VB metrics are available only when fixed catch is deselected.":"No fixed-catch results were supplied for this OM.")+
      (omSelect.value==='om23'&&componentSelect.value==='North'?" Near-zero catch in this component makes relative numerical rankings uninformative.":"");
    update();
  }
  function selectOM() {
    const components=unique(allRows.filter(d=>d.om_code===omSelect.value).map(d=>d.component));
    const names={CJM:"Single stock (CJM)",North:"Northern stock",Southern:"Southern stock"};
    componentSelect.innerHTML=components.map(c=>`<option value="${c}">${names[c]||c}</option>`).join("");
    componentSelect.disabled=components.length===1;
    selectComponent();
  }
''' + s[end:]
 s=s.replace('  <div class="scorecard-controls">','''  <div class="scorecard-controls">
    <section class="scorecard-panel">
      <h3>Operating model</h3>
      <label for="om-select">Choose an OM</label>
      <select id="om-select" class="form-select"></select>
      <label for="component-select">Stock component</label>
      <select id="component-select" class="form-select"></select>
    </section>''',1)
 s=s.replace('  <div id="scorecard-error"','  <p id="om-context" class="scorecard-note" aria-live="polite"></p>\n  <div id="scorecard-error"',1)
 old='''  document.querySelectorAll("#cmp-options input,#metric-options input")
    .forEach(input=>input.addEventListener("change",update));
  update();'''
 new='''  document.getElementById("cmp-options").addEventListener("change",()=>{
    const selected=selectedValues("cmp-options");
    cmps.forEach(mp=>selected.includes(mp)?cmpSelection.add(mp):cmpSelection.delete(mp));
    refreshMetricOptions();update();
  });
  document.getElementById("metric-options").addEventListener("change",update);
  omSelect.addEventListener("change",selectOM);
  componentSelect.addEventListener("change",selectComponent);
  selectOM();'''
 assert old in s
 s=s.replace(old,new)
 s=s.replace('    renderCustomWeights(selectedMetrics);','''    ["score-table","weight-table","quilt-table","score-plot"].forEach(id=>document.getElementById(id).innerHTML="");
    renderCustomWeights(selectedMetrics);''')
 s=s.replace('const normalized=normalize(filtered,selectedMetrics,scaling);','if(filtered.length!==selectedCmps.length*selectedMetrics.length) throw new Error("Incomplete CMP–metric coverage in this OM.");\n      const normalized=normalize(filtered,selectedMetrics,scaling);')
 s=s.replace('three retained CMPs','retained CMPs and fixed-catch reference').replace('all eight CMPs','all CMPs and fixed-catch reference')
 s=s.replace('subtitle: "Alternative browser application using the current reference-OM performance metrics"','subtitle: "Reference and robustness OMs with separate stock components"')
 s=s.replace('Select CMPs and metrics, choose a','Select an OM, stock component, CMPs and metrics; choose a',1)
 # Plain-language wording for the published scorecards.
 for old_text,new_text in [('This browser-based explorer reproduces the relative-preference scorecard\nwithout requiring R or a Shiny server. Select an OM, stock component, CMPs and metrics; choose a\nweighting scheme, or enter weights manually. Scores are recalculated relative\nto the selected CMP set and are **not absolute acceptability scores or agreed\nmanagement preferences**.', 'Choose an operating model (OM), stock component, candidate management procedures (CMPs) and indicators. Set how much weight each indicator receives. Scores compare the selected CMPs; managers can use them to explore their priorities and assess performance alongside agreed biological requirements.'), ('they express relative performance, not an absolute acceptability threshold.', 'they express performance relative to the selected CMPs. Biological acceptability requires a separately agreed threshold.'), ('Scores are relative within this selection; OMs are not pooled.', 'Scores compare CMPs within this OM and stock component.'), ('No fixed-catch results were supplied for this OM.', 'Fixed-catch results are available for the reference OM only.'), ('the direction-consistent reciprocal is used', 'the calculation is'), ('supplied reference benchmark', 'supplied reference comparison')]:
  s=s.replace(old_text,new_text)
 p.write_text(s)
print('Configured both scorecards for 10 OMs and 14 OM/components; fixed catch only in reference')
