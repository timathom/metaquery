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
) as xs:integer {
  sql:connect($db-uri, $db-user, $db-pw)
};








