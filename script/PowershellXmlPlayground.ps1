class XmlPlayground{
    
    [System.Xml.XmlDocument]$file
    
    XmlPlayground([string]$filePath){
        [System.Xml.XmlDocument]$this.file = new-object System.Xml.XmlDocument
        $this.file.Load($filePath)
    }

    Attributes(){
        $v = $this.file.SelectNodes("/testsuites");
        Write-Host "Total Attributes Count: " $v.Count
        foreach($testSuitesNode in $v){
            Write-Host $testSuitesNode.NodeType
            Write-Host $testSuitesNode.GetType()
            Write-Host $testSuitesNode.Attributes.GetType()
            Write-Host $testSuitesNode.Attributes.ItemOf("duration").GetType()
            Write-Host $testSuitesNode.Attributes.ItemOf("duration").Value
            Write-Host $testSuitesNode.Attributes.ItemOf(1).Value
            
        }
    }
}

$filePath = "C:\Users\bhansm\Desktop\JUnitXRayIntegration\reports\sample2.xml"
$vo = [XmlPlayground]::new($filePath);