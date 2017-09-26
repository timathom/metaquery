xquery version "3.1";

(:~ 
 :
 : Module name:  Metaquery Main
 : Module version:  0.0.1
 : Date:  September 12, 2017
 : License: GPLv3
 : XQuery extensions used: 
 : XQuery specification: 3.1
 : Module overview: An XRX framework and set of XQuery functions for harvesting 
 : MARC records from OCLC for copy cataloging.
 : Dependencies: BaseX, XSLTForms, Index Data's Metaproxy, MarcEdit 
 : @author @timathom
 : @version 0.0.1
 : @see https://github.com/timathom/metaquery
 :
:)

module namespace mqy = "https://metadatafram.es/metaquery/mqy/";
import module namespace mqy-sql = "https://metadatafram.es/metaquery/sql/" at 
  "mqy-sql.xqm";
declare namespace math = "http://www.w3.org/2005/xpath-functions/math";
declare namespace sql = "http://basex.org/modules/sql";
declare namespace err = "http://www.w3.org/2005/xqt-errors";
declare namespace mqy-errs = "https://metadatafram.es/metaquery/mqy-errors/";
declare namespace marc = "http://www.loc.gov/MARC21/slim";

(:~ 
 : 
 : 
 : 
 : @param $db-uri as xs:anyURI
 : @param $db-user as xs:string
 : @param $db-pw as xs:string
 : @return query results as element()
 : @error BXSQ0001: an SQL exception occurs, e.g., missing JDBC driver or no 
 : existing relation. 
 :
 :)
declare function mqy:connect(
  $db-uri as xs:anyURI, 
  $db-user as xs:string, 
  $db-pw as xs:string
) as item() {
  try 
  {
    sql:connect($db-uri, $db-user, $db-pw)  
  } 
  catch * 
  {
    <mqy:error>
    {
      "Error [" 
      || $err:code 
      || "]: " 
      || $err:description
    }
    </mqy:error>
  }  
};

declare
  %updating
function mqy:setup() {
  if (db:exists("options"))
  then (
    db:drop("options"),
    db:create("options", doc("../../config/mqy-options.xml"), "options")
  )
  else 
    db:create("options", doc("../../config/mqy-options.xml"), "options"),
  if (db:exists("mappings"))
  then (
    db:drop("mappings"),
    db:create("mappings", doc("../../config/mqy-mappings.xml"), "mappings")  
  )
  else
    db:create("mappings", doc("../../config/mqy-mappings.xml"), "mappings")  
};

declare 
  %updating
function mqy:atomize-data(
  $data as item()*,
  $map as item()*
) {
  
    
};

declare function mqy:options-to-url(
  $options as element()
) as element(mqy:sru) {
  <sru xmlns="https://metadatafram.es/metaquery/mqy/">
    <head>
    {
      $options/base 
      || $options/db 
      || "?version=1.1&amp;operation=" 
      || $options/op 
      || "&amp;query="
    }
    </head>
    <tail>
    {
      "&amp;startRecord=" 
      || $options/start 
      || "&amp;maximumRecords=" 
      || $options/max 
      || "&amp;recordSchema=" 
      || $options/schema
    }
    </tail>
  </sru>
};

declare function mqy:clean-isbn(
  $isbn as xs:string?
) as xs:string? {
  replace($isbn, "[^\d|X|x]", "")  
};

declare function mqy:map-query(  
  $data as item()*,
  $mappings as item()
) as element(mqy:mapped) {
  <mqy:mapped>
  {      
    for $r in $data/*
    return
      copy $m := $mappings
      modify 
      (
        for $d in $m/mqy:mapping/mqy:data/*        
        return 
        (
          delete node $d[$r/*[name(.) = name($d)]
                        [. ! count(.//.) eq 1]]/../..,
          replace value of node $d with $r/*[name(.) = name($d)]          
        )          
      )
      return $m 
  }
  </mqy:mapped> 
};

declare function mqy:build-query(
  $mapped as item()*
) as element(mqy:queries) {
  <mqy:queries>
  {
    for $m in $mapped//mqy:mappings
    return
      <mqy:query>
      {
        for $s in $m/mqy:mapping
        return
          <mqy:string 
            index="{$s/mqy:index}" 
            bool="{$s/mqy:index/@bool}">
          {
            if ($s/mqy:index eq "dc.title")
            then attribute { "title" } { $s/mqy:data/*}
            else (),
            let $i := $s/mqy:index,
                $b := $i/@bool,
                $d := $s/mqy:data
            return 
            (                         
              if ($i eq "local.isbn")
              then mqy:clean-isbn($d/*)
              else 
                "&quot;" 
                || encode-for-uri(lower-case(string-join($d/*, " ")))
                || "&quot;"            
            )
          }
          </mqy:string>    => trace()    
      }
      </mqy:query>   
  }
  </mqy:queries>
};

declare function mqy:compile-query-string(
  $options as item(),  
  $query as item()
) as xs:string {
  ($options//mqy:head || $query || $options//mqy:tail)
};

declare function mqy:run-queries(  
  $queries as item()*,
  $sru as item()
) as item()* {    
  <mqy:responses>
  {    
    for $query in $queries//mqy:query 
    let $isbn :=
      if ($query/mqy:string[@index eq "local.isbn"])
      then 
        mqy:send-query(
          mqy:compile-query-string(
            $sru, 
            <mqy:string>
            {
              $query/mqy:string/@index[. eq "local.isbn"]
              || "="
              || $query/mqy:string[@index eq "local.isbn"] 
            }
            </mqy:string>            
          )
        ) 
      else ()
    return (
      file:write(
      "/home/tat2/Desktop/marcxml/raw/" 
      || "marc"           
      || random:uuid()
      || ".xml",
      <mqy:response title="{$query/mqy:string/@title}">
      { trace($query/mqy:string/@title/string(), "Title: "),
        if ($isbn//marc:record)
        then $isbn
        else
          let $full :=
            mqy:send-query(
              mqy:compile-query-string(
                $sru,
                <mqy:string>
                { 
                  "("
                  ||                
                  (if ($query/mqy:string[@bool eq "NONE"]
                                        [@index ne "local.isbn"])
                  then 
                    $query/mqy:string/@index[@bool eq "NONE"]
                                            [. ne "local.isbn"] 
                    || "="
                    || $query/mqy:string[@bool eq "NONE"]
                                        [@index ne "local.isbn"] 
                  else 
                    if ($query/mqy:string[@bool eq "OR"])
                    then (
                      " OR " 
                      || $query/mqy:string[@bool eq "OR"]/@index 
                      || "="
                      || $query/mqy:string[@bool eq "OR"]
                      || ")"
                    )
                    else
                      if ($query/mqy:string[@bool eq " AND "])
                      then (
                        ") AND ("
                        || $query/mqy:string[@bool eq " AND "]/@index
                        || "="
                        || $query/mqy:string[@bool eq " AND "]                  
                        || ")"                 
                      )
                      else ())
                }
                </mqy:string> => trace()
              )
            )          
          return
            if ($full//marc:record)
            then $full
            else
              let $title :=                                          
                mqy:send-query(
                  ($sru//mqy:head                      
                  || "dc.title=" 
                  || $query/mqy:string[@index eq "dc.title"]                      
                  || $sru//mqy:tail)  
                )                  
              return
                if ($title)
                then $title
                else
                  <mqy:message>No results for the query: 
                  {
                    string($query/mqy:string[not(@index eq "local.isbn")])
                  }
                  </mqy:message>                                                
      } 
      </mqy:response>                   
      ) 
    )
  }</mqy:responses> 
};


(:~ 
 : Helper for submitting query
 :)
declare function mqy:send-query(
  $href as xs:string
) as item()* {
  try 
  {
    http:send-request(
      <http:request 
        method="get" 
        href="{$href}"/> 
    )
  }
  catch *
  {
    <mqy:error>
    {
      "Error [" 
      || $err:code 
      || "]: " 
      || $err:description
    }
    </mqy:error>
  }
};

(:~ 
 : Filter results
 :)
 
 (:~ 
  : Filter cataloging level, etc.
  :)
declare function mqy:filter-levels(
  $marc as element(marc:record),
  $filters as element(mqy:filters)
) as element()* {
  if (
    $marc
    [
      *:leader/substring(., 7, 1) = $filters/mqy:biblevel
      and *:leader/substring(., 18, 1) = xquery:eval($filters/mqy:catlevel)
    ]
  )
  then $marc
  else 
    <mqy:message code="0">
    {
      $marc
    }
    </mqy:message>  
};
 
declare function mqy:filter-results(
  $responses as element(mqy:responses),
  $options as element(mqy:options),
  $keyword as xs:string?
) as item()* {
  file:write(
    "/home/tat2/Desktop/marcxml/filtered/" 
    || "marc"           
    || random:uuid()
    || ".xml",    
    <mqy:filtered>
    {
    for $marc in $responses//marc:record
    let $local := $marc/ancestor::mqy:response/@title/string()
    return
      if (
        $marc
        [
          *:leader/substring(., 7, 1) = "a"
            and *:leader/substring(., 18, 1) = (" ", "1", "I", "L")              
        ]
        [
          if (*:controlfield[@tag = "008"]/substring(., 34, 1) ne "0") 
          then true()
          else *:datafield[starts-with(@tag, "6")][@ind2 eq "0"]
        ]
        [
          contains(lower-case(*:datafield[@tag = "040"]), "dlc") 
            or *:subfield[@code = "e"] = "rda"          
            or contains(*:datafield[@tag = "042"], "pcc")          
        ]                                                
        [
          *:datafield[@tag = ("050", "090")] 
          => string-join() 
          => string-length() ge 7
        ]
        [
          let $check :=
            mqy:check-title(
              *:datafield[@tag = "245"]/*:subfield[@code = "a"],
              $local
            )
          return
            if (not($check/mqy:error))
            then true()
            else false()
        ]
        [
          contains(string(lower-case(.)), lower-case($keyword))
        ]      
      )
      then 
        <mqy:best>
        {
          let $record := mqy:prune-fields($marc),
              $id     := 
                $record/*:datafield[@tag = "010"]/*:subfield
                => normalize-space(),
              $path :=
                "/home/tat2/Desktop/marcxml/"
                || $id
                || "marc-" 
                || random:uuid() 
                || ".xml"
          return 
          (
            file:write(
              $path,
              $record
            ),
            mqy:write-marc21(
              $id,
              $path,
              $options
            )            
          )                      
        }
        </mqy:best>
      else      
        <mqy:other>
        {
          file:write(
            "/home/tat2/Desktop/marcxml/other/" 
            || "marc"           
            || random:uuid()
            || ".xml",
            $marc
          )
        }
        </mqy:other>  
      }
      </mqy:filtered>
    )
};

(:~ 
 : Check titles
 :)
declare function mqy:check-title(
  $local-title as xs:string*,
  $found-title as xs:string*
) as item() { 
  try 
  {
    strings:levenshtein(
      $found-title,
      $local-title           
    ) ge 0.8     
  }
  catch *
  {
    <mqy:error>
    {
      "Error [" 
      || $err:code 
      || "]: " 
      || $err:description
    }
    </mqy:error>
  }   
   
};

(:~ 
 : Prune fields
 :)
declare function mqy:prune-fields(
  $record as element()
) as element(marc:record) {    
   copy $r := $record
   modify (
     delete node $r/*[starts-with(@tag, "9")],
     delete node $r/*[@tag eq "029"]
   )
   return $r
};

(:~ 
 : Write MARC21
 :)
declare function mqy:write-marc21(
  $id as xs:string,
  $path as xs:string,
  $options as element(mqy:options)
) {
  
  let $store :=
    proc:execute(
      "mono",
      ($options/mqy:MarcEdit/string(),
      "-s",
      $path,
      "-d",
      $options/mqy:marc21 
      || $id
      || "marc-" 
      || random:uuid() 
      || ".dat",
      "-xmlmarc",
      "-marc8")   
    )      
  return $store
};

(:~ 
 : Write all MARC21 files to folder
 :)
declare function mqy:write-all-marc21(
  $records as item(),
  $options as element(mqy:options)
) {
  for $record in $records//mqy:best//marc:record
  let $file := $record/*:datafield[@tag = "010"]/*:subfield
               => normalize-space()
  return (
    file:write(
      $options/mqy:marcxml 
      || $file 
      || "marc-" 
      || random:uuid() 
      || ".xml", $record
    ),
    mqy:write-marc21($record, (), $options)
  )
    
};