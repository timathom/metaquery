xquery version "3.1";

module namespace test = "https://metadatafram.es/test/";
declare namespace math = "http://www.w3.org/2005/xpath-functions/math";
declare namespace sql = "http://basex.org/modules/sql";
declare namespace mqy-errs = "https://metadatafram.es/metaquery/mqy-errors/";
declare namespace marc = "http://www.loc.gov/MARC21/slim";

import module namespace mqy = "https://metadatafram.es/metaquery/mqy/" 
  at "../src/modules/mqy.xqm";
import module namespace mqy-sql = "https://metadatafram.es/metaquery/sql/" at 
  "../src/modules/mqy-sql.xqm";
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
        <ISBN>978-159711244-4</ISBN>
        <FirstName>Rob</FirstName>
        <FirstName2>Arnold</FirstName2>
        <LastName>Hornstra</LastName>
        <LastName2>Van Bruggen</LastName2>
        <Title>The Sochi Project</Title>
        <Publisher>Badger &amp; Press</Publisher>
      </record>
      <record>
        <ISBN>978-123456789-2</ISBN>
        <FirstName>Abadfasdfsadfc</FirstName>
        <FirstName2>Deadsfsadfasdffg</FirstName2>
        <LastName>Hijkasdfasdfasdfl</LastName>
        <LastName2>Mnopqrasdfasdfasdfs</LastName2>
        <Title>Tasdfasdfasdfasdfasdfuv</Title>
        <Publisher></Publisher>
      </record>
    </csv>,  
  "data"),
  db:create("records", doc("fixtures/mqy-records.xml"), "records"),
  db:create("marc21"),
  file:create-dir("/Users/tt434/Desktop/marcxml/"),
  file:create-dir("/Users/tt434/Desktop/marcxml/other/"),
  file:create-dir("/Users/tt434/Desktop/marc21/")
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
  let $options := db:open("options")/*,
      $sru     := mqy:options-to-url($options)
  return (
    unit:assert-equals(
      $sru//mqy:head/string(),
      "https://metadatafram.es/metaproxy/oclcbib?version=1.1&amp;operation=" 
      || "searchRetrieve&amp;query="
    ),
    unit:assert-equals(
      $sru//mqy:tail/string(),
      "&amp;startRecord=1&amp;maximumRecords=25&amp;recordSchema=marcxml"
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
      mqy:map-query($data, $mappings)/*/mqy:mapping/mqy:data[LastName ne ""]
    ),
    unit:assert(
      not(mqy:map-query($data, $mappings)[2]/*/mqy:mapping/mqy:data[Publisher])  
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
      $mapped   := mqy:map-query($data, $mappings)[1]
  return (
    unit:assert(
      mqy:build-query($mapped)/mqy:query[1]/mqy:string[1]
        = "local.isbn=9781597112444"
    ),
    unit:assert(
      mqy:build-query($mapped)/mqy:query[1]/mqy:string[3]
        = " OR bath.any=&quot;van%20bruggen&quot;"
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
      $mapped   := mqy:map-query($data, $mappings)[1]
  return
  (
    unit:assert-equals
    (
      mqy:compile-query-string(
        $sru, 
        mqy:build-query($mapped)/mqy:query[1]/mqy:string[1]
      ),            
      "https://metadatafram.es/metaproxy/oclcbib?version=1.1&amp;operation=" 
      || "searchRetrieve&amp;query="
      || "(local.isbn=9781597112444)"
      || "&amp;startRecord=1&amp;maximumRecords="
      || "25&amp;recordSchema=marcxml"
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
      $mapped   := mqy:map-query($data, $mappings)
  return    
    unit:assert-equals(
      count(
        mqy:run-queries(
          mqy:build-query($mapped),
          $sru          
        )//mqy:response 
      ), 2 
    )
};

(:~ 
 : mqy:run-queries
 : Run queries in stages (ISBN, name-title-publisher, title-publisher, title)
 :)
declare
  %unit:test
function test:run-progressive-queries() {
  let $options  := db:open("options")/mqy:options,
      $sru      := mqy:options-to-url($options),
      $mappings := db:open("mappings")/mqy:mappings,
      $data     := db:open("data")/*,
      $mapped   := mqy:map-query($data, $mappings)
  return (
    unit:assert-equals(
      mqy:run-queries(
        mqy:build-query($mapped),
        $sru          
        )//mqy:response[1]//*:query/string(), "(local.isbn=9781597112444)"
      ),
    unit:assert(
      mqy:run-queries(        
        mqy:build-query($mapped),
        $sru
      )//mqy:response[2]//*:numberOfRecords ! . = 0
      )
    )  
};

(:~ 
 : mqy:filter-results
 : Filter records based on quality parameters
 :)
declare
  %unit:test
function test:filter-results() {
  let $options  := db:open("options")/mqy:options,
      $sru      := mqy:options-to-url($options),
      $mappings := db:open("mappings")/mqy:mappings,
      $data     := db:open("data")/*,
      $mapped   := mqy:map-query($data, $mappings),
      $records  := db:open("records")/*
  return (
    unit:assert(
      (mqy:run-queries(
        mqy:build-query($mapped),
        $sru        
      )//mqy:response[1]//marc:record[1]/marc:leader/substring(., 7, 1)) = "a"
    )
    ,
    unit:assert(
     $records//marc:leader/substring(., 18, 1) = (" ", "1", "I", "L")
    )
    ,
    unit:assert(
      $records//marc:record[not(marc:controlfield[@tag = "006"]) 
        and not(marc:controlfield[@tag = "007"])]
    )
    ,
    unit:assert(
      $records//marc:record[
        if (marc:controlfield[@tag = "008"]/substring(., 34, 1) ne "0") 
        then true()
        else marc:datafield[starts-with(@tag, "6")][@ind2 eq "0"]
      ]
    )
    ,
    unit:assert(
      $records//*:record[
        contains(lower-case(*:datafield[@tag = "040"]), "dlc") 
          or *:subfield[@code = "e"] = "rda"          
          or contains(*:datafield[@tag = "042"], "pcc")          
        ]                                                
    )
    ,
    unit:assert(
      $records//marc:record[
        marc:datafield[@tag = ("050", "090")]             
          => string-join() 
          => string-length() ge 7
      ]                                                
    )
    ,
    unit:assert(
      $records//marc:record[
        marc:datafield[@tag = ("050", "090")]             
          => string-join() 
          => string-length() ge 7
      ]                                                
    )
  )
    
};

(:~ 
 : mqy:check-titles
 : Sanity check for titles
 :)
declare 
  %unit:test
function test:check-titles() {
  let $options  := db:open("options")/mqy:options,
      $sru      := mqy:options-to-url($options),
      $mappings := db:open("mappings")/mqy:mappings,
      $data     := db:open("data")/*,
      $mapped   := mqy:map-query($mappings, $data),
      $records  := db:open("records")/*
  return (
    unit:assert(
      strings:levenshtein(
        "The Sochi project :"
        , 
        $data//record[1]/Title/string(.)
      ) ge 0.8      
    ),
    unit:assert(
     mqy:check-title(
       $data//record[1]/Title/string(.),
       $records//*:record[1]/*:datafield[@tag = "245"]/*:subfield[@code = "a"]
       /string(.)
     )      
    )
  )
    
};

(:~ 
 : mqy:prune-fields
 : Remove unwanted data fields
 :)
declare
  %unit:test
function test:prune-fields() {
  let $options  := db:open("options")/mqy:options,
      $sru      := mqy:options-to-url($options),
      $mappings := db:open("mappings")/mqy:mappings,
      $data     := db:open("data")/*,
      $mapped   := mqy:map-query($mappings, $data),
      $records  := db:open("records")/*
  return (
        
    unit:assert(
      mqy:prune-fields(
        $records//*:record[last()]
      )
    )  
  )
};

(:~ 
 : mqy:write-marc21
 : Convert MARCXML to MARC21
 :)
declare
  %unit:test
function test:write-marc21() {
  let $options  := db:open("options")/mqy:options,
      $sru      := mqy:options-to-url($options),
      $mappings := db:open("mappings")/mqy:mappings,
      $data     := db:open("data")/*,
      $mapped   := mqy:map-query($data, $mappings),
      $records  := db:open("records")
  return (        
    file:write(
      "/Users/tt434/Desktop/marcxml/test.xml", 
      $records//*:record[last()]
    ),
    unit:assert-equals(
      mqy:write-marc21($records//*:record[last()], $options)//code/string(), "0"
    )          
  )
};

(:~ 
 : mqy:write-marc21
 : Convert MARCXML to MARC21
 :)
declare
  %unit:test
function test:write-all-marc21() {
  let $options  := db:open("options")/mqy:options,
      $sru      := mqy:options-to-url($options),
      $mappings := db:open("mappings")/mqy:mappings,
      $data     := db:open("data")/*,
      $mapped   := mqy:map-query($data, $mappings),
      $records  := db:open("records")
  return (           
    mqy:write-all-marc21($records, $options),
    unit:assert(
      file:list("/Users/tt434/Desktop/marcxml/") => count() gt 0,
      file:list("/Users/tt434/Desktop/marc21/") => count() gt 0
    )          
  )
};

(:~ 
 : Test windowing for parallel processing
 :)
declare
  %unit:test
function test:windowing() {
  let $options  := db:open("options")/mqy:options,
      $mappings := db:open("mappings")/mqy:mappings,
      $sru      := mqy:options-to-url($options),
      $records  :=
        for $csv in 1 to 3
        return db:open("csv" || $csv)/*,
      $db-mappings := mqy:map-query($records, $mappings)
  return
    unit:assert(
      (for tumbling window $w in $db-mappings/*
       start $first at $s when true()
       end at $e when $e - $s = 5
       return <mqy:test>{$w}</mqy:test>) ! count(*) = 6 
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
  db:drop("data"),
  db:drop("records"),
  db:drop("marc21"),
  file:delete("/Users/tt434/Desktop/marcxml/", true()),
  file:delete("/Users/tt434/Desktop/marc21/", true())
  
};
