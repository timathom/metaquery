xquery version "3.1";

(:~ 
 :
 : Module name:  Metaquery SQL
 : Module version:  0.0.1
 : Date:  September 12, 2017
 : License: GPLv3
 : XQuery extensions used: BaseX SQL Module
 : XQuery specification: 3.1
 : Module overview: An XRX framework and set of XQuery functions for harvesting 
 : MARC records from OCLC for copy cataloging.
 : Dependencies: BaseX, XSLTForms, Index Data's Metaproxy, MarcEdit 
 : @author @timathom
 : @version 0.0.1
 : @see https://github.com/timathom/metaquery
 : @see http://docs.basex.org/wiki/SQL
 :
:)

module namespace mqy-sql = "https://metadatafram.es/metaquery/sql/";
declare namespace math = "http://www.w3.org/2005/xpath-functions/math";
declare namespace sql = "http://basex.org/modules/sql";
declare namespace err = "http://www.w3.org/2005/xqt-errors";
declare namespace mqy-errs = "https://metadatafram.es/metaquery/mqy-errors/";

(:~ 
 : 
 : 
 : 
 : @return SQL prepared statement as xs:string
 : @error BXSQ0001: an SQL exception occurs, e.g., missing JDBC driver or no 
 : existing relation. 
 : @error BXSQ0003: number of parameters differs from number of placeholders
 :
 :)
declare function mqy-sql:prepared(
  $conn as xs:integer,
  $params as element(sql:parameters),
  $sql as xs:string
) as element()+ {    
  let $query := sql:execute-prepared(sql:prepare($conn, $sql), $params)  
  return 
    if ($query) 
    then 
      if ($query/sql:column)
      then $query
      else
        <mqy-sql:message>No results for the query: {$sql}</mqy-sql:message>
    else () (: Something went wrong! :)      
};
