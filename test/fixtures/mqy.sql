SELECT DISTINCT bib_text.bib_id,
                Rawtohex(yaledb.Getbibsubfield(bib_text.bib_id, '245', 'a')) AS main_title,
                Rawtohex(yaledb.Getbibsubfield(bib_text.bib_id, '300', 'a')) AS phys_desc
FROM            bib_text
WHERE           rownum = 1