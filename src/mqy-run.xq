xquery version "3.1";

import module namespace mqy = "https://metadatafram.es/metaquery/mqy/" 
  at "modules/mqy.xqm";
declare namespace marc = "http://www.loc.gov/MARC21/slim";


(: mqy:setup() :)



let $setup    := (
  (: file:delete("/home/tat2/Desktop/oclc/marcxml/", true()),
  file:delete("/home/tat2/Desktop/oclc/marc21/", true()), :)
  file:create-dir("/home/tat2/Desktop/oclc/marcxml/"),
  file:create-dir("/home/tat2/Desktop/oclc/marcxml/other/"),
  file:create-dir("/home/tat2/Desktop/oclc/marcxml/filtered/"),
  file:create-dir("/home/tat2/Desktop/oclc/marcxml/raw/"),
  file:create-dir("/home/tat2/Desktop/oclc/marc21/")
)
let $options  := db:open("options")/mqy:options,
    $mappings := db:open("mappings")/mqy:mappings,
    $sru      := mqy:options-to-url($options),
    $records  :=
      for $csv in reverse(1 to 3)
      return db:open("csv" || $csv)/*,
    $db-mappings := mqy:map-query($records, $mappings)
  return (
    let $queries := mqy:build-query($db-mappings)            
    for tumbling window $w in $queries//mqy:query
      start $first at $s when true()
      end at $e when $e - $s = 5
    let $funcs :=    
      for $x in $w
      return
        function() {          
          mqy:run-queries($x, $sru) 
          => mqy:filter-results($options, "")
        } 
    return      
      xquery:fork-join($funcs)
  )