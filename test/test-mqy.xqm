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
  db:create("options", doc("fixtures/mqy-options.xml"), "options"),
  db:create("mappings", doc("fixtures/mqy-mappings.xml"), "mappings"),
  db:create("data",
    <csv>
      <record>
        <ISBN>978-988189661-2</ISBN>
        <FirstName>Rob</FirstName>
        <FirstName2>Arnold</FirstName2>
        <LastName>Hornstra</LastName>
        <LastName2>Van Bruggen</LastName2>
        <Title>The Sochi Project</Title>
        <Publisher>Badger &amp; Press</Publisher>
      </record>
      <record>
        <ISBN>978-123456789-2</ISBN>
        <FirstName>Abc</FirstName>
        <FirstName2>Defg</FirstName2>
        <LastName>Hijkl</LastName>
        <LastName2>Mnopqrs</LastName2>
        <Title>Tuv</Title>
        <Publisher></Publisher>
      </record>
    </csv>,  
  "data")
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
  %unit:ignore
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
  %unit:ignore
function test:simple-query-with-results() {
  let $conn := test:connect-to-db(),
    $params := 
      <sql:parameters>
        <sql:parameter type="string">245</sql:parameter>
        <sql:parameter type="string">a</sql:parameter>
        <sql:parameter type="string">245</sql:parameter>
        <sql:parameter type="string">b</sql:parameter>      
        <sql:parameter type="double">1</sql:parameter>  
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
  %unit:ignore
function test:simple-query-no-results() {
  let $conn := test:connect-to-db(),
    $params := 
      <sql:parameters>
        <sql:parameter type="string">299</sql:parameter>
        <sql:parameter type="string">a</sql:parameter>                                                         
        <sql:parameter type="string">299</sql:parameter>
        <sql:parameter type="string">b</sql:parameter>
        <sql:parameter type="double">0</sql:parameter>
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
  %unit:test
  %unit:ignore
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
      mqy-sql:prepared($conn, $params, $sql)[self::mqy-sql:error]
    )    
};

(:~ 
 : mqy:options-to-url
 : Convert options to SRU URL
 :)
declare
  %unit:test
function test:convert-options-to-url() {  
  let $options := db:open("options")/mqy:options,
      $sru     := mqy:options-to-url($options)
  return (
    unit:assert-equals(
      $sru/mqy:head/string(),
      "https://metadatafram.es/metaproxy/yul?version=1.1&amp;operation=" 
      || "searchRetrieve&amp;query="
    ),
    unit:assert-equals(
      $sru/mqy:tail/string(),
      "&amp;startRecord=1&amp;maximumRecords=5&amp;recordSchema=marcxml"
    )
  )  
};

(:~ 
 : mqy:clean-isbn
 : Ensure ISBNs are searchable
 :)
declare
  %unit:test
function test:clean-isbn() {
  let $isbn  := "ISBN 0-942159-11-X",
      $isbn2 := "094215911x"
  return (
    unit:assert-equals(mqy:clean-isbn($isbn), "094215911X"),
    unit:assert-equals(mqy:clean-isbn($isbn2), "094215911x")
  )
};

(:~ 
 : Helper for queries
 :)
declare function test:get-data-for-queries() {
  
};

(:~ 
 : mqy:map-query
 : Map data values to template
 :)
declare
  %unit:test
function test:map-query() {
  let $mappings := db:open("mappings")/mqy:mappings,
      $data     := db:open("data")/*
  return (
    unit:assert(
      mqy:map-query($mappings, $data)[1]/*/mqy:mapping/mqy:data[FirstName ne ""]
    ),
    unit:assert(
      not(mqy:map-query($mappings, $data)[2]/*/mqy:mapping/mqy:data[Publisher])  
    )
  )
};

(:~ 
 : mqy:build-query
 : Build SRU query string from template
 :)
declare
  %unit:test
function test:build-query() {  
  let $mappings := db:open("mappings")/mqy:mappings,
      $data     := db:open("data")/*,
      $mapped   := mqy:map-query($mappings, $data)[1]
  return (
    unit:assert(
      mqy:build-query($mapped)/mqy:query[1]/mqy:string[1] 
        = "local.isbn=9789881896612"
    ),
    unit:assert(
      mqy:build-query($mapped)/mqy:query[1]/mqy:string[3] 
        = "%20OR%20bath.personalName=Lundgren%20Wassink"
    )
  )
};

(:~ 
 : mqy:compile-query-string
 : Compile query strings
 :)
declare
  %unit:test
function test:compile-query-string() {
  let $options  := db:open("options")/mqy:options,
      $sru      := mqy:options-to-url($options),
      $mappings := db:open("mappings")/mqy:mappings,
      $data     := db:open("data")/*,
      $mapped   := mqy:map-query($mappings, $data)[1]
  return
  (
    unit:assert-equals
    (
      mqy:compile-query-string(
        $sru, 
        mqy:build-query($mapped)/mqy:query[1]/mqy:string[1]
      ),            
      "https://metadatafram.es/metaproxy/yul?version=1.1&amp;operation=" 
      || "searchRetrieve&amp;query="
      || "local.isbn=9789881896612"
      || "&amp;startRecord=1&amp;maximumRecords="
      || "5&amp;recordSchema=marcxml"
    )
  )
};

(:~ 
 : mqy:run-queries
 : Run the queries in order of preference and respond to results
 :)
declare
  %unit:test
function test:run-queries() {
  let $options  := db:open("options")/mqy:options,
      $sru      := mqy:options-to-url($options),
      $mappings := db:open("mappings")/mqy:mappings,
      $data     := db:open("data")/*,
      $mapped   := mqy:map-query($mappings, $data)[1]
  return
    unit:assert(
      mqy:run-queries(
        $sru,
        mqy:build-query($mapped) 
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
  db:drop("options"),
  db:drop("mappings"),
  db:drop("data")
};
