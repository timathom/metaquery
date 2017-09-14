xquery version "3.1";

module namespace test = "https://metadatafram.es/test/";
declare namespace math = "http://www.w3.org/2005/xpath-functions/math";
declare namespace sql = "http://basex.org/modules/sql";
declare namespace mqy-errs = "https://metadatafram.es/metaquery/mqy-errors/";

import module namespace mqy = "https://metadatafram.es/metaquery/mqy/" 
  at "../src/mqy.xqm";
import module namespace mqy-sql = "https://metadatafram.es/metaquery/sql/" at 
  "../src/mqy-sql.xqm";
import module namespace test-queries = "https://metadatafram.es/test/queries/" 
  at "fixtures/queries.xqm";
  
(:~ 
 : Generate test fixtures for the current test module
 :)
declare
  %unit:before-module
  %updating
function test:get-connect-params() {
  db:create("connect", doc("fixtures/mqy-params.xml"), "params"),
  db:create("options", doc("fixtures/mqy-options.xml"), "options")
};

(: Connect to DB :)
declare function test:connect-to-db() {
  let $creds  := db:open("connect")/*
  return
    mqy:connect($creds/conn/uri, $creds/conn/user, $creds/conn/pw)
};
  
(:~ 
 : mqy:connect
 : Connect to local catalog
 :)
declare
  %unit:test
function test:connect() {     
  unit:assert-equals(
    test:connect-to-db(), 0
  )
};

(:~ 
 : mqy-sql:prepared
 : Query local catalog
 :)
declare
  %unit:test
function test:simple-query-with-results() {
  let $conn := test:connect-to-db(),
    $params := 
      <sql:parameters>
        <sql:parameter type="string">245</sql:parameter>
        <sql:parameter type="string">a</sql:parameter>
      </sql:parameters>,
    $sql    := 
      test-queries:simple-query(())
  return 
    unit:assert(
      mqy-sql:prepared($conn, $params, $sql)/sql:column
    )    
};

(:~ 
 : mqy-sql:prepared
 : Query local catalog
 :)
declare
  %unit:test
function test:simple-query-no-results() {
  let $conn := test:connect-to-db(),
    $params := 
      <sql:parameters>
        <sql:parameter type="string">299</sql:parameter>
        <sql:parameter type="string">a</sql:parameter>                                                         
      </sql:parameters>,
    $sql    := 
      test-queries:simple-query(())
  return 
    unit:assert(
      mqy-sql:prepared($conn, $params, $sql)[self::mqy-sql:message] 
    )    
};

(:~ 
 : mqy-sql:prepared
 : Query local catalog
 :)
declare
  %unit:test("expected", "bxerr:BXSQ0003")
function test:simple-query-with-error() {
  let $conn := test:connect-to-db(),
    $params := 
      <sql:parameters>
        <sql:parameter type="string"></sql:parameter>       
      </sql:parameters>,
    $sql    := 
      test-queries:simple-query(())
  return 
    unit:assert(
      mqy-sql:prepared($conn, $params, $sql)
    )    
};

(:~ 
 : mqy:options-to-url
 : Convert options to SRU URL
 :)
declare
  %unit:test
function test:convert-options-to-url() {  
  let $options := db:open("options"),
      $url     := mqy:options-to-url($options)  
  return (
    unit:assert-equals(
       $url/head, 
       "https://metadatafram.es/metaproxy/yul?version=1.1&amp;operation=" ||
       "searchRetrieve&amp;query=&quot;"
    ),
    unit:assert-equals(
      $url/tail,
      "&quot;&amp;startRecord=1&amp;maximumRecords=5&amp;recordSchema=marcxml"
    )
  )  
};

(:~ 
 : Remove test fixtures for the current test module
 :)
declare
  %unit:after-module
  %updating
function test:clear-connect-params() {
  db:drop("connect"),
  db:drop("options")
};
