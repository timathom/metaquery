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
  $mappings as element(mqy:mappings),
  $data as item()
) as element(mqy:mapped) {
  <mqy:mapped>
  {      
    for $r in $data/record
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
  $mapped as element(mqy:mapped)
) as element(mqy:queries) {
  <mqy:queries>
  {
    for $m at $p in $mapped/*
    return
      <mqy:query>
      {
        for $s in $m/mqy:mapping
        return
          <mqy:string index="{$s/mqy:index}">
          {
            let $i := $s/mqy:index,
                $b := $i/@bool,
                $d := $s/mqy:data
            return 
            (           
              if ($b ne "NONE")
              then 
                (" " || $b || " " )
                => encode-for-uri()  
              else (),                 
              $i || "=",              
              if (count($d/*) gt 1)
              then 
                string-join($d/*, " ") 
                => encode-for-uri()                              
              else 
                if ($i eq "local.isbn")
                then mqy:clean-isbn($d/*)
                else encode-for-uri($d/*)
            ) 
            => string-join()
          }
          </mqy:string>        
      }
      </mqy:query>  
  }
  </mqy:queries> => trace()
};

declare function mqy:compile-query-string(
  $sru as element(mqy:sru),  
  $query as element(mqy:string)
) as xs:string {
  $sru/mqy:head || $query || $sru/mqy:tail
};

