xquery version "3.1";

module namespace test = "https://metadatafram.es/tests/";
declare namespace math = "http://www.w3.org/2005/xpath-functions/math";
declare namespace sql = "http://basex.org/modules/sql";
declare namespace mqy-errs = "https://metadatafram.es/metaquery/mqy-errors/";

import module namespace mqy = "https://metadatafram.es/metaquery/mqy/" 
  at "../src/mqy.xqm";
import module namespace mqy-sql = "https://metadatafram.es/metaquery/sql/" at 
  "../src/mqy-sql.xqm";
import module namespace test-queries = "https://metadatafram.es/tests/queries/" 
  at "fixtures/queries.xqm";
  
(:~ 
 : Generate test fixtures for the current test module
 :)
declare
  %unit:before-module
  %updating
function test:get-connect-params() {
  db:create("connect", doc("fixtures/mqy-connect-params.xml"), "params")
};
  
(:~ 
 : mqy:connect
 : Connect to local catalog
 :)
declare
  %unit:test
function test:connect() {   
  let $params := db:open("connect")/*
  return
    unit:assert-equals(
      mqy:connect($params/uri, $params/user, $params/pw), 0
    )
};

(:~ 
 : mqy-sql:prepared
 : Query local catalog
 :)
declare
  %unit:test
function test:simple-query-with-results() {
  let $creds  := db:open("connect")/*,
      $conn   := mqy:connect($creds/uri, $creds/user, $creds/pw),
      $params := 
        <sql:parameters>
          <sql:parameter type="string">245</sql:parameter>
          <sql:parameter type="string">a</sql:parameter>
          <sql:parameter type="string">300</sql:parameter>
          <sql:parameter type="string">a</sql:parameter>
        </sql:parameters>,
      $sql    := 
        test-queries:simple-query-with-results(
          <mqy-sql:aliases>
            <mqy-sql:aliases>main_title</mqy-sql:aliases>
            <mqy-sql:aliases>phys_desc</mqy-sql:aliases>
          </mqy-sql:aliases>
        )
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
   let $creds := db:open("connect")/*,
      $conn   := mqy:connect($creds/uri, $creds/user, $creds/pw),
      $params := 
        <sql:parameters>
          <sql:parameter type="string">299</sql:parameter>
          <sql:parameter type="string">a</sql:parameter>
          <sql:parameter type="string">399</sql:parameter>
          <sql:parameter type="string">a</sql:parameter>
        </sql:parameters>,
      $sql    := 
        test-queries:simple-query-no-results(
          <mqy-sql:aliases>
            <mqy-sql:aliases>main_title</mqy-sql:aliases>
            <mqy-sql:aliases>phys_desc</mqy-sql:aliases>
          </mqy-sql:aliases>
        )
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
   let $creds := db:open("connect")/*,
      $conn   := mqy:connect($creds/uri, $creds/user, $creds/pw),
      $params := 
        <sql:parameters>
          <sql:parameter type="string">299</sql:parameter>
          <sql:parameter type="string"></sql:parameter>          
        </sql:parameters>,
      $sql    := 
        test-queries:simple-query-with-error(
          <mqy-sql:aliases>
            <mqy-sql:aliases>main_title</mqy-sql:aliases>
            <mqy-sql:aliases>phys_desc</mqy-sql:aliases>
          </mqy-sql:aliases>
        )
  return 
    unit:assert(
      mqy-sql:prepared($conn, $params, $sql)
    )    
};




(:~ 
 : Remove test fixtures for the current test module
 :)
declare
  %unit:after-module
  %updating
function test:clear-connect-params() {
  db:drop("connect")
};
