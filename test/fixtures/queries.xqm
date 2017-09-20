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
  SELECT bib_text.isbn, 
         Rawtohex(bib_text.author) as author, 
         Rawtohex(yaledb.Getbibsubfield(bib_text.bib_id, ?, ?)) as main_title,
         Rawtohex(yaledb.Getbibsubfield(bib_text.bib_id, ?, ?)) as subtitle
  FROM   bib_text
  WHERE  ROWNUM = ?
  ]``
};

declare function test-queries:action-dates(
  $aliases as element(mqy-sql:aliases)?
) as xs:string {
  ``[
  SELECT bib_master.bib_id, bib_master.create_date, bib_history.operator_id, bib_history.action_date
  FROM   bib_master LEFT JOIN bib_history ON bib_master.bib_id = bib_history.bib_id
  WHERE  (bib_history.action_date Between to_date(?, 'yyyy/mm/dd') And to_date (?, 'yyyy/mm/dd'))
  AND    (bib_history.operator_id IN (?))
  ]``
};

declare function test-queries:single-bib(
  $aliases as element(mqy-sql:aliases)?
) as xs:string {
  ``[
  SELECT bib_master.bib_id, bib_master.create_date, bib_history.operator_id, bib_history.action_date
  FROM   bib_master LEFT JOIN bib_history ON bib_master.bib_id = bib_history.bib_id
  WHERE  (bib_master.bib_id = ?) 
  ]``
};