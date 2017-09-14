xquery version "3.1";

module namespace test-queries = "https://metadatafram.es/test/queries/";
declare namespace math = "http://www.w3.org/2005/xpath-functions/math";
declare namespace sql = "http://basex.org/modules/sql";
declare namespace mqy-errs = "https://metadatafram.es/metaquery/mqy-errors/";
declare namespace mqy-sql = "https://metadatafram.es/metaquery/sql/";


declare function test-queries:simple-query(
  $aliases as element(mqy-sql:aliases)?
) as xs:string {
  ``[
  SELECT Rawtohex(yaledb.Getbibsubfield(bib_text.bib_id, ?, ?))
  FROM   bib_text
  WHERE  ROWNUM = 1
  ]``
};