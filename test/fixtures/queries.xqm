xquery version "3.1";

module namespace test-queries = "https://metadatafram.es/tests/queries/";
declare namespace math = "http://www.w3.org/2005/xpath-functions/math";
declare namespace sql = "http://basex.org/modules/sql";
declare namespace mqy-errs = "https://metadatafram.es/metaquery/mqy-errors/";
declare namespace mqy-sql = "https://metadatafram.es/metaquery/sql/";


declare function test-queries:simple-query-with-results(
  $aliases as element(mqy-sql:aliases)
) as xs:string {
  ``[
  SELECT DISTINCT bib_text.bib_id,
                  Rawtohex(yaledb.Getbibsubfield(bib_text.bib_id, ?, ?)) AS `{$aliases/alias[1]}`,
                  Rawtohex(yaledb.Getbibsubfield(bib_text.bib_id, ?, ?)) AS `{$aliases/alias[2]}`
  FROM            bib_text
  WHERE           rownum = 1
  ]``
};

declare function test-queries:simple-query-no-results(
  $aliases as element(mqy-sql:aliases)
) as xs:string {
  ``[
  SELECT Rawtohex(yaledb.Getbibsubfield(bib_text.bib_id, ?, ?)) AS `{$aliases/alias[1]}`,
         Rawtohex(yaledb.Getbibsubfield(bib_text.bib_id, ?, ?)) AS `{$aliases/alias[2]}`
  FROM   bib_text
  WHERE  rownum = 1 
  ]``
};

declare function test-queries:simple-query-with-error(
  $aliases as element(mqy-sql:aliases)
) as xs:string {
  ``[
  SELECT Rawtohex(yaledb.Getbibsubfield(bib_text.bib_id, ?, ?)) AS `{$aliases/alias[1]}`,
         Rawtohex(yaledb.Getbibsubfield(bib_text.bib_id, ?, ?)) AS `{$aliases/alias[2]}`
  FROM   bib_text
  WHERE  rownum = 1 
  ]``
};