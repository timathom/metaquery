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
  "../src/mqy-sql.xqm";
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

declare function mqy:options-to-url(
  $ops as element(mqy:options)
) as element(mqy:sru) {
  <sru xmlns="https://metadatafram.es/metaquery/mqy/">
    <head>
    {
      $ops/base 
      || $ops/db 
      || "?version=1.1&amp;operation=" 
      || $ops/op 
      || "&amp;query="
    }
    </head>
    <tail>
    {
      "&amp;startRecord=" 
      || $ops/start 
      || "&amp;maximumRecords=" 
      || $ops/max 
      || "&amp;recordSchema=" 
      || $ops/schema
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
    for $r in $data//record
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
  $mapped as item()
) as item() {
  <mqy:queries>
  {
    for $m at $p in $mapped//mqy:mappings
    return
      <mqy:query>
      {
        for $s in $m/mqy:mapping
        return
          <mqy:string index="{$s/mqy:index}" >
          {
            if ($s/mqy:index eq "dc.title")
            then attribute { "title" } { $s/mqy:data/Title }
            else (),
            let $i := $s/mqy:index,
                $b := $i/@bool,
                $d := $s/mqy:data
            return 
            (                         
              if ($b eq "AND")
              then 
                (") " || $b || " (" )
              else 
                if ($b ne "NONE")
                then (" " || $b || " ")
                else (),                 
              $i || "=",              
              if (count($d/*) gt 1)
              then 
                "&quot;" || encode-for-uri(
                  lower-case(string-join($d/*, " "))
                ) || "&quot;"
              else 
                if ($i eq "local.isbn")
                then mqy:clean-isbn($d/*)
                else "&quot;" || encode-for-uri(lower-case($d/*)) || "&quot;"
            ) 
            => string-join()
          }
          </mqy:string>        
      }
      </mqy:query>  
  }
  </mqy:queries>
};

declare function mqy:compile-query-string(
  $sru as item(),  
  $query as element(mqy:string)
) as xs:string {
  ($sru/mqy:head || "(" || $query || ")" || $sru/mqy:tail)
};

declare function mqy:run-queries(  
  $queries as item(),
  $sru as item()  
) as item()* {    
  <mqy:responses>
  {
    for $query in $queries/mqy:query
    let $isbn :=
      if ($query/mqy:string[@index eq "local.isbn"])
      then 
        mqy:send-query(
          mqy:compile-query-string(
            $sru, 
            $query/mqy:string[@index eq "local.isbn"]
          )
        ) 
      else ()
    return (
      <mqy:response title="{$query/mqy:string/@title}">
      { 
        if ($isbn//marc:record)
        then $isbn
        else
          let $all :=
            mqy:send-query(
              mqy:compile-query-string(
                $sru, 
                <mqy:string>{
                  string-join(
                    for $s in $query/mqy:string[not(@index eq "local.isbn")] 
                    return $s
                  )        
                }</mqy:string>
              )   
            ) 
          return
            if ($all//marc:record)
            then $all
            else
              let $title-pub :=
                if ($query/mqy:string[@index eq "dc.publisher"])
                then
                  mqy:send-query(
                    ($sru/mqy:head                      
                    || string-join(
                          (
                            "dc.title=" 
                            || $query/mqy:string[@index eq "dc.title"]
                               => substring-after("="),
                            "dc.publisher=" 
                            || $query/mqy:string[@index eq "dc.publisher"]
                               => substring-after("=")
                          )
                       )
                    || $sru/mqy:tail)                        
                  )
                else ()
              return                  
                if ($title-pub//marc:record)
                then $title-pub
                else
                  let $title :=                                          
                    mqy:send-query(
                      ($sru/mqy:head                      
                      || "dc.title=" 
                      || $query/mqy:string[@index eq "dc.title"]
                           => substring-after("=")
                      || $sru/mqy:tail)  
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
      || $err:description
    }
    </mqy:error>
  }
};

(:~ 
 : Filter results
 :)
declare function mqy:filter-results(
  $responses as element(mqy:responses)
) as item()* {
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
          and not(*:controlfield[@tag = "006"]) 
          and not(*:controlfield[@tag = "007"])        
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
        contains(string(lower-case(.)), "photo")
      ]
      
    )
    then 
      <mqy:best>
      {
        mqy:prune-fields(
          $marc
        ) => trace()
      }
      </mqy:best>
    else
      
      <mqy:other>
      {
        file:write(
          "/Users/tt434/Desktop/marcxml/other/" 
          || "marc"           
          || random:uuid()
          || ".xml",
          $marc => trace()
        )
      }
      </mqy:other>  
    }
    </mqy:filtered>
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
) as xs:boolean {    
   copy $r := $record
   modify (
     delete node $r/*[starts-with(@tag, "9")],
     delete node $r/*[@tag eq "029"]
   )
   return (
     if ($r[not(*[starts-with(@tag, "9")]) and not(*[@tag eq "029"])])
     then true()
     else false()     
   )
};

(:~ 
 : Write MARC21
 :)
declare function mqy:write-marc21(
  $record as item(),
  $options as element(mqy:options)
) {
  
  let $file  := $record/*:datafield[@tag = "010"]/*:subfield
                => normalize-space(),
      $store :=
        proc:execute(
          "mono",
          ($options/mqy:MarcEdit/string(),
          "-s",
          $options/mqy:marcxml || $file || "marc-" || random:uuid() || ".xml",
          "-d",
          $options/mqy:marc21 || $file || "marc-" || random:uuid() || ".dat",
          "-xmlmarc",
          "-marc8")   
        )
  return (
    $store
  )
    
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
      $options/mqy:marcxml || $file || "marc-" || random:uuid() ||  ".xml", $record
    ),
    mqy:write-marc21($record, $options)
  )
    
};

