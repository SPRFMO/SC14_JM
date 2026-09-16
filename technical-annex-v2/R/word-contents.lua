-- A populated, clickable contents list for the distributed Word document.
-- Headings retain their native Word styles for the Navigation pane.
function Pandoc(doc)
  if not FORMAT:match("docx") or not doc.meta["word-contents"] then return doc end
  local entries = {}
  for _, block in ipairs(doc.blocks) do
    if block.t == "Header" and block.level <= 2 and block.identifier ~= "" then
      local text = pandoc.utils.stringify(block.content)
      local entry = pandoc.Para({pandoc.Link(text, "#" .. block.identifier)})
      if block.level == 2 then
        entry = pandoc.Div({entry}, pandoc.Attr("", {}, {["custom-style"]="TOC 2"}))
      end
      table.insert(entries, entry)
    end
  end
  local blocks = {pandoc.Header(1,"Contents",pandoc.Attr("contents",{"unnumbered"}))}
  for _, entry in ipairs(entries) do table.insert(blocks, entry) end
  table.insert(blocks,pandoc.RawBlock("openxml",'<w:p><w:r><w:br w:type="page"/></w:r></w:p>'))
  for _, block in ipairs(doc.blocks) do table.insert(blocks, block) end
  doc.blocks = blocks
  return doc
end
