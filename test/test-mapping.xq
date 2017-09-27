xquery version "3.1";

import module namespace mqy = "https://metadatafram.es/metaquery/mqy/" 
  at "../src/modules/mqy.xqm";
declare namespace marc = "http://www.loc.gov/MARC21/slim";

(: let $mapping :=
<mappings xmlns="https://metadatafram.es/metaquery/mqy/">
  <mapping>
    <data>
      <ISBN xmlns="">9780956332219</ISBN>
    </data>
    <index bool="NONE">local.isbn</index>
  </mapping>
  <mapping>
    <data>
      <LastName></LastName>
      <FirstName></FirstName>
    </data>
    <index bool="NONE">bath.any</index>
  </mapping>
  <mapping>
    <data>
      <LastName2></LastName2>
      <FirstName2></FirstName2>
    </data>
    <index bool="OR">bath.any</index>
  </mapping>
  <mapping>
    <data>
      <Title>The Lost Symmetry</Title>
    </data>
    <index bool="AND">dc.title</index>
  </mapping>
  <mapping>
    <data>
      <!-- <Publisher xmlns=""/> -->
    </data>
    <index bool="OR">dc.publisher</index>
  </mapping>
  <mapping>
    <data>
      <!-- <Year>2008</Year> -->
    </data>
    <index bool="AND">dc.date</index>
  </mapping>
</mappings>
return
  let $queries := mqy:build-query(<mqy:mapped>{$mapping}</mqy:mapped>),
      $groups  :=       
        for $query at $p in $queries/mqy:query/mqy:string[not(@index eq "local.isbn")]
        group by $key := $query/@index
        return
          if (count($query) ge 2)
          then
            <mqy:string p="{$p}" index="{$key}">
            {       
              let $string := 
                for $q in $query
                return $key || "=" || $q
              return          
                "(" || string-join($string, " OR ") || ")"                                       
            }
            </mqy:string>
          else $query,
      $join    :=
        <mqy:string>
        {
          if ($groups[@p])
          then
            string-join(
              for $g in $groups[not(@p)]
              return "(" || $g/@index || "=" || $g || ")", 
              " AND "
            )        
          else
            string-join(
              for $g in $groups[not(@p)]
              return "(" || $g/@index || "=" || $g || ")"
            )
        }
        </mqy:string>  
  return (
    if ($groups[@p])
    then $groups[@p] || " AND " || $join
    else $join
  ) :)
    
    
      
(:
<mqy:queries xmlns:mqy="https://metadatafram.es/metaquery/mqy/">
  <mqy:query>
    <mqy:string index="bath.any" bool="NONE">"martina%20maffini"</mqy:string>
    <mqy:string index="bath.any" bool="NONE">"veronica%20mengoli"</mqy:string>
    <mqy:string index="dc.title" bool="AND" title="beat beat beat">"beat%20beat%20beat"</mqy:string>
    <mqy:string index="dc.date" bool="AND">"2009"</mqy:string>
    <mqy:string index="dc.publisher" bool="OR">"kaugummi%20books"</mqy:string>
  </mqy:query>
</mqy:queries>

<mqy:string xmlns:mqy="https://metadatafram.es/metaquery/mqy/" p="1 2">
  <mqy:string index="bath.any" bool="NONE">"martina%20maffini"</mqy:string>
  <mqy:string index="bath.any" bool="NONE">"veronica%20mengoli"</mqy:string>
</mqy:string>
<mqy:string xmlns:mqy="https://metadatafram.es/metaquery/mqy/" p="3">
  <mqy:string index="dc.title" bool="AND" title="beat beat beat">"beat%20beat%20beat"</mqy:string>
</mqy:string>
<mqy:string xmlns:mqy="https://metadatafram.es/metaquery/mqy/" p="4">
  <mqy:string index="dc.date" bool="AND">"2009"</mqy:string>
</mqy:string>
<mqy:string xmlns:mqy="https://metadatafram.es/metaquery/mqy/" p="5">
  <mqy:string index="dc.publisher" bool="OR">"kaugummi%20books"</mqy:string>
</mqy:string>

:)

let $responses :=
<mqy:response xmlns:mqy="https://metadatafram.es/metaquery/mqy/" title="How Terry likes his coffee" date="172010">
  <http:response xmlns:http="http://expath.org/ns/http-client" status="200" message="OK">
    <http:header name="Server" value="nginx/1.10.3 (Ubuntu)"/>
    <http:header name="Connection" value="keep-alive"/>
    <http:header name="Content-Length" value="6014"/>
    <http:header name="Date" value="Wed, 27 Sep 2017 01:14:41 GMT"/>
    <http:header name="Content-Type" value="text/xml"/>
    <http:body media-type="text/xml"/>
  </http:response>
  <zs:searchRetrieveResponse xmlns:zs="http://www.loc.gov/zing/srw/">
    <zs:version>1.1</zs:version>
    <zs:numberOfRecords>1</zs:numberOfRecords>
    <zs:records>
      <zs:record>
        <zs:recordSchema>opac</zs:recordSchema>
        <zs:recordPacking>xml</zs:recordPacking>
        <zs:recordData>
          <opacRecord>
  <bibliographicRecord>
<record xmlns="http://www.loc.gov/MARC21/slim">
  <leader>01570cam a2200361Ia 4500</leader>
  <controlfield tag="001">13020008</controlfield>
  <controlfield tag="005">20170105152415.0</controlfield>
  <controlfield tag="008">110809s2010    ne ao         000 0 eng d</controlfield>
  <datafield tag="035" ind1=" " ind2=" ">
    <subfield code="a">(OCoLC)ocn746086287</subfield>
  </datafield>
  <datafield tag="040" ind1=" " ind2=" ">
    <subfield code="a">GZM</subfield>
    <subfield code="b">eng</subfield>
    <subfield code="c">GZM</subfield>
    <subfield code="d">OCLCA</subfield>
    <subfield code="d">OCLCF</subfield>
    <subfield code="d">OCLCQ</subfield>
  </datafield>
  <datafield tag="020" ind1=" " ind2=" ">
    <subfield code="a">9789081562812</subfield>
  </datafield>
  <datafield tag="020" ind1=" " ind2=" ">
    <subfield code="a">9081562819</subfield>
  </datafield>
  <datafield tag="043" ind1=" " ind2=" ">
    <subfield code="a">e-ne---</subfield>
  </datafield>
  <datafield tag="100" ind1="1" ind2=" ">
    <subfield code="a">Roekel, Florian van.</subfield>
  </datafield>
  <datafield tag="245" ind1="1" ind2="0">
    <subfield code="a">How Terry likes his coffee :</subfield>
    <subfield code="b">a photo odyssey into office life /</subfield>
    <subfield code="c">by Florian van Roekel.</subfield>
  </datafield>
  <datafield tag="250" ind1=" " ind2=" ">
    <subfield code="a">1st ed.</subfield>
  </datafield>
  <datafield tag="260" ind1=" " ind2=" ">
    <subfield code="a">[Amsterdam?] :</subfield>
    <subfield code="b">Florian van Roekel,</subfield>
    <subfield code="c">2010</subfield>
    <subfield code="e">(Amsterdam :</subfield>
    <subfield code="f">Spruijt)</subfield>
  </datafield>
  <datafield tag="300" ind1=" " ind2=" ">
    <subfield code="a">84 unnumbered pages :</subfield>
    <subfield code="b">illustrations ;</subfield>
    <subfield code="c">21 x 31 cm</subfield>
  </datafield>
  <datafield tag="336" ind1=" " ind2=" ">
    <subfield code="a">text</subfield>
    <subfield code="b">txt</subfield>
    <subfield code="2">rdacontent</subfield>
  </datafield>
  <datafield tag="337" ind1=" " ind2=" ">
    <subfield code="a">unmediated</subfield>
    <subfield code="b">n</subfield>
    <subfield code="2">rdamedia</subfield>
  </datafield>
  <datafield tag="338" ind1=" " ind2=" ">
    <subfield code="a">volume</subfield>
    <subfield code="b">nc</subfield>
    <subfield code="2">rdacarrier</subfield>
  </datafield>
  <datafield tag="590" ind1=" " ind2=" ">
    <subfield code="a">BEIN Leclair iPL 4: No. 191. Inscription of artist. From the Indie Photobook Library/Larissa Leclair Collection.</subfield>
  </datafield>
  <datafield tag="500" ind1=" " ind2=" ">
    <subfield code="a">Edition of 500 copies.</subfield>
  </datafield>
  <datafield tag="500" ind1=" " ind2=" ">
    <subfield code="a">Editing and design by Sybren Kuiper of Den Haag.</subfield>
  </datafield>
  <datafield tag="500" ind1=" " ind2=" ">
    <subfield code="a">Part of the photographers final exam for his Bachelor of Photography degree at the Royal Academy of Arts in Den Haag.</subfield>
  </datafield>
  <datafield tag="650" ind1=" " ind2="0">
    <subfield code="a">Photography</subfield>
    <subfield code="z">Netherlands</subfield>
    <subfield code="v">Pictorial works.</subfield>
  </datafield>
  <datafield tag="650" ind1=" " ind2="0">
    <subfield code="a">Work environment</subfield>
    <subfield code="z">Netherlands</subfield>
    <subfield code="v">Pictorial works.</subfield>
  </datafield>
  <datafield tag="650" ind1=" " ind2="7">
    <subfield code="a">Photography.</subfield>
    <subfield code="2">fast</subfield>
    <subfield code="0">(OCoLC)fst01061714</subfield>
  </datafield>
  <datafield tag="650" ind1=" " ind2="7">
    <subfield code="a">Work environment.</subfield>
    <subfield code="2">fast</subfield>
    <subfield code="0">(OCoLC)fst01180270</subfield>
  </datafield>
  <datafield tag="651" ind1=" " ind2="7">
    <subfield code="a">Netherlands.</subfield>
    <subfield code="2">fast</subfield>
    <subfield code="0">(OCoLC)fst01204034</subfield>
  </datafield>
  <datafield tag="655" ind1=" " ind2="7">
    <subfield code="a">Pictorial works.</subfield>
    <subfield code="2">fast</subfield>
    <subfield code="0">(OCoLC)fst01423874</subfield>
  </datafield>
  <datafield tag="692" ind1="1" ind2="4">
    <subfield code="a">Leclair, Larissa</subfield>
    <subfield code="x">Ownership.</subfield>
  </datafield>
  <datafield tag="710" ind1="2" ind2=" ">
    <subfield code="a">Indie Photobook Library/Larissa Leclair Collection.</subfield>
    <subfield code="5">CtY-BR</subfield>
  </datafield>
</record>
  </bibliographicRecord>
<holdings>
 <holding>
  <typeOfRecord>x</typeOfRecord>
  <encodingLevel>4</encodingLevel>
  <receiptAcqStatus>4</receiptAcqStatus>
  <generalRetention>8</generalRetention>
  <completeness>1</completeness>
  <dateOfReport>901128</dateOfReport>
  <nucCode>lsfbeir</nucCode>
  <localLocation>LSF- BEINECKE</localLocation>
  <callNumber>Leclair iPL 4</callNumber>
  <circulations>
   <circulation>
    <availableNow value="1"/>
    <itemId>11528093</itemId>
    <renewable value="0"/>
    <onHold value="0"/>
   </circulation>
  </circulations>
 </holding>
</holdings>
</opacRecord>
        </zs:recordData>
        <zs:recordPosition>1</zs:recordPosition>
      </zs:record>
    </zs:records>
    <zs:echoedSearchRetrieveRequest>
      <zs:version>1.1</zs:version>
      <zs:query>local.isbn=9789081562812</zs:query>
      <zs:startRecord>1</zs:startRecord>
      <zs:maximumRecords>5</zs:maximumRecords>
      <zs:recordPacking>xml</zs:recordPacking>
      <zs:recordSchema>opac</zs:recordSchema>
    </zs:echoedSearchRetrieveRequest>
  </zs:searchRetrieveResponse>
</mqy:response>
return (
   <mqy:filtered>
   {
    for $resp in $responses
    let $local := $resp/@title/string(),
        $date  := $resp/@date/string(),
        $raw   :=
          file:write(
            "/home/tat2/Desktop/marcxml/raw/"              
            || "marc-"
            || random:uuid()
            || ".xml",
            $resp
          )
    for $marc in $resp//marc:record
    return (      
      if (
        $marc
        [
          *:leader/substring(., 7, 1) = "a"
            and *:leader/substring(., 18, 1) = (" ", "1", "I", "L")              
        ]
        [
          if (*:controlfield[@tag = "008"]/substring(., 34, 1) ne "0") 
          then true()
          else *:datafield[starts-with(@tag, "6")][@ind2 eq "0"]
        ]
        [
          *:datafield[@tag = "040"]/*:subfield[@code = "b"] = "eng"
          or 
          ((*:datafield[@tag = ("050", "090")])
          => string-join() 
          => string-length() ge 7)
          or
          contains(lower-case(*:datafield[@tag = "040"]), "dlc") 
            or *:subfield[@code = "e"] = "rda"          
            or contains(*:datafield[@tag = "042"], "pcc")          
        ]        
        [
          let $check :=
            mqy:check-title(
              *:datafield[@tag = "245"]/*:subfield[@code = "a"],
              $local
            )
          return
            if ($check = true())
            then true()
            else false()
        ]
        
        [
          if (normalize-space($date))
          then
            if (
              matches(
                *:datafield[starts-with(@tag, "26")]/*:subfield[@code = "c"], 
                substring($date, string-length($date) - 3)
              )
            )
            then true()
            else false()
          else true()
        ]      
      )
      then 
        <mqy:best>
        {
          
          let $record := mqy:prune-fields($marc),
              $id     := 
                $record/*:datafield[@tag = "010"]/*:subfield
                => normalize-space(),
              $path :=
                "/home/tat2/Desktop/marcxml/filtered/"
                || $id
                || "marc-" 
                || random:uuid() 
                || ".xml"
          return 
          (            
            file:write(
              $path,
              $record
            ),
            mqy:write-marc21(
              $id,
              $path,
              $options
            )            
          )                      
        }
        </mqy:best>
      else      
        <mqy:other>
        {
          file:write(
              "/home/tat2/Desktop/marcxml/other/"              
              || "marc-"
              || random:uuid()
              || ".xml",
              $marc
            )
        }
        </mqy:other>  
      )
      }
   </mqy:filtered>)