for $record in /csv/record
let $names := $record/FirstName ! tokenize(., "[\n]")
let $lines :=
  for $name in $names
  return
    if (string-length($name) le 60)
    then $name
    else ()
let $puncts := $lines ! tokenize(., "[,|;|/|\-|'&amp;']")
let $cleaned :=
  for $punct in $puncts
  return
    <FirstName>{normalize-space(replace($punct, "­", ""))}</FirstName>
    [normalize-space(.)]
return (
  delete node $record/FirstName,
  for $c in $cleaned
  return
    insert node $c into $record
  

)
  


