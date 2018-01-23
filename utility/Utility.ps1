class UtilityProcessor{
    [System.Xml.XmlDocument]$file
    
    UtilityProcessor($filePath){
        [System.Xml.XmlDocument]$this.file = new-object System.Xml.XmlDocument
        $this.file.load($filePath)
        $this.init()
    }

    init(){
        $dayNodes = $this.file.SelectNodes('//Day')
        foreach($dayNode in $dayNodes){
            $text = $dayNode.InnerText
            $m = $text -match "([-+])(\d)"
            $t = "<CURRDATE" + $($Matches[1]) + $($Matches[2]) + ",dd&gt;"
            Write-Host $t
            $dayNode.set_innerXML($null)
            $NEWCHILD = $this.file.CreateElement("newElement")
            $NEWCHILD.set_innerXML("TESTTEXT")
            $dayNode.AppendChild($this.file.CreateTextNode($t))
            Write-Host $matches[0]
            #$this.testSuites = $this.testSuites + [JUnitTestSuiteNodeProcessor]::new($testSuiteNode)
        }
        $this.file.save("C:\Users\bhansm\Desktop\JUnitXRayIntegration\utility\file.xml")
    }

}

[UtilityProcessor]::new('C:\Users\bhansm\Downloads\ATM04ATM04.xml')