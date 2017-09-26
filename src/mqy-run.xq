xquery version "3.1";

import module namespace mqy = "https://metadatafram.es/metaquery/mqy/" 
  at "modules/mqy.xqm";
declare namespace marc = "http://www.loc.gov/MARC21/slim";

(:
mqy:setup()
:)


let $setup    := (
  file:delete("/home/tat2/Desktop/marcxml/", true()),
  file:delete("/home/tat2/Desktop/marc21/", true()),
  file:create-dir("/home/tat2/Desktop/marcxml/"),
  file:create-dir("/home/tat2/Desktop/marcxml/other/"),
  file:create-dir("/home/tat2/Desktop/marcxml/filtered/"),
  file:create-dir("/home/tat2/Desktop/marcxml/raw/"),
  file:create-dir("/home/tat2/Desktop/marc21/")
)
let $options  := db:open("options")/mqy:options,
    $mappings := db:open("mappings")/mqy:mappings,
    $sru      := mqy:options-to-url($options),
    $records  :=
      for $csv in 1 to 3
      return db:open("csv" || $csv)/*,
    $db-mappings := mqy:map-query($records, $mappings)
  return (    
    for tumbling window $w in $db-mappings/*
      start $first at $s when true()
      end at $e when $e - $s = 5
    let $funcs :=      
      for $x in $w
      return     
        function() {
          mqy:build-query(<mqy:mapped>{$x}</mqy:mapped>) 
          => mqy:run-queries($sru) 
          => mqy:filter-results($options, "photo")
        } 
    return xquery:fork-join($funcs)
  )
    

  
