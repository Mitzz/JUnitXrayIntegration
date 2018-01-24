class UtilityProcessor{
    [System.Xml.XmlDocument]$file
    [string]$outputFilePath
    
    UtilityProcessor($filePath, $outputFilePath){
        [System.Xml.XmlDocument]$this.file = new-object System.Xml.XmlDocument
        $this.outputFilePath = $outputFilePath
        $this.file.load($filePath)
        $this.init()
    }

    init(){
        $dayNodes = $this.file.SelectNodes('//Day')
        foreach($dayNode in $dayNodes){
            $text = $dayNode.InnerText
            $m = $text -match "(\w*)\s*([-+]?)\s*(\d?)"
            if($m){
                $monthNode = $dayNode.PreviousSibling
                $yearNode = $monthNode.PreviousSibling
               
                if(($monthNode.NodeType -eq 'Element' -and $monthNode.LocalName -eq 'Month') -and ($yearNode.NodeType -eq 'Element' -and $yearNode.LocalName -eq 'Year')){
                    $dayNode.set_innerXML($null)
                    $monthNode.set_innerXML($null)
                    $yearNode.set_innerXML($null)
                    $plusMinusText = $Matches[2]
                    $numberText = $Matches[3]
                    $yearText = "<CURRDATE" + $($plusMinusText) + $($numberText) + ",yyyy>"
                    $monthText = "<CURRDATE" + $($plusMinusText) + $($numberText) + ",mm>"
                    $dayText = "<CURRDATE" + $($plusMinusText) + $($numberText) + ",dd>"
                
                    #doc.CreateCDataSection("Hi, How are you..??")
                    #$dayNode.AppendChild($this.file.CreateCDataSection($dayText))
                    $dayNode.AppendChild($this.file.CreateTextNode($dayText))
                    $monthNode.AppendChild($this.file.CreateTextNode($monthText))
                    $yearNode.AppendChild($this.file.CreateTextNode($yearText))
                }
            } else {
                Write-Host $m
            }
            
        }
        $this.file.save($this.outputFilePath)
        (Get-Content $this.outputFilePath).replace('&lt;', '<') | Set-Content $this.outputFilePath
        (Get-Content $this.outputFilePath).replace('&gt;', '>') | Set-Content $this.outputFilePath
        
    }

}

[UtilityProcessor]::new('C:\Users\bhansm\Downloads\ATM04ATM04.xml', "C:\Users\bhansm\Desktop\JUnitXRayIntegration\utility\file.xml")