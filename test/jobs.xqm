xquery version "3.1";

module namespace jt = "http://metadatafram.es/testing/jobs/";

declare
  %rest:path("/test")
  %rest:GET
  %output:method("xhtml")
  %output:omit-xml-declaration("no")
  %output:doctype-public("-//W3C//DTD XHTML 1.0 Transitional//EN")
  %output:doctype-system("http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd")
function jt:load-page() {  
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>Page 1</title>
    </head>
    <body>
      <div>
        <h1>This is the first page</h1>
        <form method="post" action="test">
        <p><input type="submit" /></p>
      </form>
      </div>
    </body>
</html>  
};


