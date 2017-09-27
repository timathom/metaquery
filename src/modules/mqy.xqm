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
      || " "
      || $err:line-number
      || " "
      || $err:additional
      || " " 
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
      copy $map := $mappings
      modify
      (
        for $d in $r/*[. ! count(.//.) ne 1],
            $m in $map/mqy:mapping/mqy:data/*[name(.) = name($d)]
        return (
          delete node $m,
          insert node $d into $m/..
        )                      
      )
      return $map
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
        let $i := $s/mqy:index,
            $b := $i/@bool,
            $data := $s/mqy:data
        for $d in $data/*[normalize-space(.)]
        return
          <mqy:string 
            index="{$s/mqy:index}" 
            bool="{$s/mqy:index/@bool}">
          {            
            if ($i eq "dc.title")
            then attribute { "title" } { $s/mqy:data/*}
            else (),                        
            (if ($i eq "local.isbn")
             then mqy:clean-isbn($d/string())
             else 
               if ($i != "dc.date")
               then 
                 "&quot;" 
                 || encode-for-uri(lower-case(replace($d, "\\", "")))
                 || "&quot;"
               else $d)
          }
          </mqy:string>
      }
      </mqy:query>   
  }
  </mqy:queries> 
};

declare function mqy:compile-query-string(
  $options as item(),  
  $query as item()*
) as xs:string {
  ($options//mqy:head || $query || $options//mqy:tail)
};

declare function mqy:run-queries(  
  $queries as item()*,
  $sru as item()
) as item()* {    
  <mqy:responses>
  {    
    for $query in $queries
    let $isbn :=
      if ($query/mqy:string[@index eq "local.isbn"])
      then 
        try
        {
          mqy:send-query(
            mqy:compile-query-string(
              $sru, 
              <mqy:string>
              {              
                "local.isbn="
                || $query/mqy:string[@index eq "local.isbn"] 
              }
              </mqy:string>            
            )
          )  
        }
        catch *
        {
          <mqy:error>
          {
            "Error [" 
      || $err:code
      || "]: " 
      || " "
      || $err:line-number
      || " "
      || $err:additional
      || " " 
      || $err:description
          }
          </mqy:error>
        }        
      else ()
    return (      
      <mqy:response 
        title="{$query/mqy:string/@title}"
        date="{$query/mqy:string[@index = 'dc.date']}">
      {
        if ($isbn//marc:record)
        then $isbn
        else
          let $full :=
            try 
            {
              mqy:send-query(
                mqy:compile-query-string(
                  $sru,                
                  (let $groups  :=       
                     for $q at $p in $query/mqy:string[@index != "local.isbn"]
                                                      [@index != "dc.date"]
                     group by $key := $q/@index
                     return
                       if (count($q) ge 2)
                       then
                         <mqy:string p="{$p}" index="{$key}">
                         {       
                           let $string := 
                             for $x in $q
                             return $key || "=" || $x
                           return          
                             "(" || string-join($string, " OR ") || ")"                                       
                         }
                         </mqy:string>
                       else $q,
                   $join    :=
                     <mqy:string>
                     {                       
                       string-join(
                         for $g in $groups[not(@p)]
                         return "(" || $g/@index || "=" || $g || ")", 
                         " AND "
                       )                               
                     }
                     </mqy:string>  
                   return (
                     if ($groups[@p])
                     then $groups[@p] || " AND " || $join
                     else $join
                   ))
                )
              )             
            }
            catch *
            {
              <mqy:error>
              {"Error [" 
              || $err:code
              || "]: " 
              || " "
              || $err:line-number
              || " "
              || $err:additional
              || " " 
              || $err:description
              }
              </mqy:error>
            }
          return (
            if ($full//marc:record)
            then $full
            else (
              let $title-date :=
                (: if ($query/mqy:string[@index eq "dc.date"][normalize-space(.)])
                then                    
                  try
                  {
                    mqy:send-query(
                      ($sru//mqy:head                      
                      || "(dc.title=" 
                      || $query/mqy:string[@index eq "dc.title"]
                      || ") AND (dc.date="
                      || $query/mqy:string[@index eq "dc.date"]           
                      || ")"      
                      || $sru//mqy:tail)  
                    )   
                  }                      
                  catch *
                  {
                    <mqy:error>
                    {
                      "Error [" 
                      || $err:code
                      || "]: " 
                      || " "
                      || $err:line-number
                      || " "
                      || $err:additional
                      || " " 
                      || $err:description
                    }
                    </mqy:error>
                  }                  
                else () :)
                ()                 
              return (
                if ($title-date//marc:record)
                then $title-date
                else (
                  if ($full//*:query[not(starts-with(., "(dc.title"))])
                  then (
                    let $title :=            
                      try
                      {
                        mqy:send-query(
                          ($sru//mqy:head                      
                          || "dc.title=" 
                          || $query/mqy:string[@index eq "dc.title"]                                        
                          || $sru//mqy:tail)  
                        ) 
                      }        
                      catch *
                      {
                        <mqy:error>
                        {
                         "Error [" 
                        || $err:code
                        || "]: " 
                        || " "
                        || $err:line-number
                        || " "
                        || $err:additional
                        || " " 
                        || $err:description
                        }
                        </mqy:error>
                      }
                    return (
                      if ($title//marc:record)
                      then $title                        
                      else
                        <mqy:message>
                        {
                          <mqy:text>No results for the query:</mqy:text>,
                          ($isbn//*:query, 
                          $full//*:query, 
                          $title-date//*:query, 
                          $title//*:query)                                                    
                        }
                        </mqy:message>
                      )
                    )
                  else
                     <mqy:message>
                      {
                        <mqy:text>No results for the query</mqy:text>(: ,
                        ($isbn//*:query, 
                        $full//*:query, 
                        $title-date//*:query, 
                        $title//*:query) :)                                                    
                      }
                      </mqy:message>                      
              )
            )             
          )                       
        )                                           
      } 
      </mqy:response> => trace()
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
      || " "
      || $err:line-number
      || " "
      || $err:additional
      || " " 
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
    <mqy:filtered>
    {
    for $resp in $responses//mqy:response
    let $local := $resp/@title/string(),
        $date  := $resp/@date/string(),
        $raw   :=
          file:write(
            "/home/tat2/Desktop/oclc/marcxml/raw/"              
            || "marc-"
            || random:uuid()
            || ".xml",
            $resp
          )
    for $marc in $resp//marc:record
 for $marc in $resp//marc:record
    return (      
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
          *:datafield[@tag = "040"]/*:subfield[@code = "b"] = "eng"
          or 
          ((*:datafield[@tag = ("050", "090")])
          => string-join() 
          => string-length() ge 7)
          or
          contains(lower-case(*:datafield[@tag = "040"]), "dlc") 
            or *:subfield[@code = "e"] = "rda"          
            or contains(*:datafield[@tag = "042"], "pcc")          
        ]        
        [
          let $check :=
            mqy:check-title(
              *:datafield[@tag = "245"]/*:subfield[@code = "a"],
              $local
            )
          return
            if ($check = true())
            then true()
            else false()
        ]
        
        [
          if (normalize-space($date))
          then
            let $pubdate := *:datafield[starts-with(@tag, "26")][1]
                            /*:subfield[@code = "c"][1]
            return
            if (
              strings:levenshtein(
                analyze-string(
                  $pubdate, 
                  "[0-9]"
                )//fn:match
                => string-join(), 
                substring($date, string-length($date) - 3)
              ) ge 0.75
            )
            then true()
            else false()
          else true()
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
                "/home/tat2/Desktop/oclc/marcxml/filtered/"
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
              "/home/tat2/Desktop/oclc/marcxml/other/"              
              || "marc-"
              || random:uuid()
              || ".xml",
              $marc
            )
        }
        </mqy:other>  
      )
      }
      </mqy:filtered>    
};

(:~ 
 : Check titles
 :)
declare function mqy:check-title(
  $local-title as xs:string*,
  $found-title as xs:string*
) as xs:boolean { 
  if (normalize-space($local-title))
  then
    try
    {
      if (strings:levenshtein(
        $found-title,
        $local-title           
      ) ge 0.75)
      then true()
      else false()  
    }
    catch *
    {
      false()    
    }
  else false()
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