Function Convert-Content {  
    [CmdletBinding()]  
    Param(  
        [ValidateNotNullOrEmpty()]  
        [string]$InputFilePath,
        [ValidateNotNullOrEmpty()]  
        [string]$OutputFilePath  
    )  
      
    Begin  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}  
          
    Process  
    {  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"  
              
        
        [UtilityProcessor]::new($InputFilePath, $OutputFilePath)
    }  
          
    End  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}  
}


class UtilityProcessor{
    [System.Xml.XmlDocument]$xmlDoc
    [string]$outputFilePath
    
    UtilityProcessor($inputFilePath, $outputFilePath){
        [System.Xml.XmlDocument]$this.xmlDoc = new-object System.Xml.XmlDocument
        $this.outputFilePath = $outputFilePath
        $this.xmlDoc.load($inputFilePath)
        $this.init()
    }

    init(){
        $dayNodes = $this.xmlDoc.SelectNodes('//Day')
        foreach($dayNode in $dayNodes){
            $text = $dayNode.InnerText
            $m = $text -match "(CURRENT)([-+])(\d*)"
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
                    $dayNode.AppendChild($this.xmlDoc.CreateTextNode($dayText))
                    $monthNode.AppendChild($this.xmlDoc.CreateTextNode($monthText))
                    $yearNode.AppendChild($this.xmlDoc.CreateTextNode($yearText))
                }
            }
            
        }
        $this.xmlDoc.save($this.outputFilePath)
        (Get-Content $this.outputFilePath).replace('&lt;', '<').replace('&gt;', '>') | Set-Content $this.outputFilePath
        #(Get-Content $this.outputFilePath).replace('&gt;', '>') | Set-Content $this.outputFilePath
        
    }

}