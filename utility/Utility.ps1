﻿Function Convert-Content {  
    [CmdletBinding()]  
    Param(  
        [ValidateNotNullOrEmpty()]  
        [string]$InputFilePath,
        [ValidateNotNullOrEmpty()]  
        [string]$OutputFilePath,
        [ValidateNotNullOrEmpty()]  
        [string]$InputDirPath  
    )  
      
    Begin  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}  
          
    Process  
    {  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"  
              
        $files = Get-ChildItem $InputDirPath | Where-Object {$_.Name -match "(?=.*.xml.LOG$)"}
        $OutputDirPath = $($InputDirPath + [System.IO.Path]::DirectorySeparatorChar + "output")
        if(-Not (Test-Path -Path $OutputDirPath)) {
            New-Item -ItemType Directory -Force -Path $OutputDirPath
        }

        foreach($file in $files){
            $fileName = $file.Name
            $InputFilePath = $file.FullName
            $OutputFilePath = $($OutputDirPath + [System.IO.Path]::DirectorySeparatorChar + $fileName) 
            Write-Host "Processing " $($InputFilePath) " ..."
            $vo = [UtilityProcessor]::new($InputFilePath, $OutputFilePath)
            $vo.execute()
        }
        
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
    }

    execute(){
        $this.init()
    }

    init(){
        $dayNodes = $this.xmlDoc.SelectNodes('//Day')
        foreach($dayNode in $dayNodes){
            $text = $dayNode.InnerText
            $m = $text -match "(CURRENT)([-+])(\d*)"
            if($m){
                $monthNode = $this.getSiblingNode($dayNode, 'Month', 'Element')
                $yearNode = $this.getSiblingNode($dayNode, 'Year', 'Element')
                
                if($monthNode -ne $null -and $yearNode -ne $null){
                    $dayNode.set_innerXML($null)
                    $monthNode.set_innerXML($null)
                    $yearNode.set_innerXML($null)
                    $plusMinusText = $Matches[2]
                    $numberText = $Matches[3]
                    $yearText = "<CURRDATE" + $($plusMinusText) + $($numberText) + ",yyyy>"
                    $monthText = "<CURRDATE" + $($plusMinusText) + $($numberText) + ",mm>"
                    $dayText = "<CURRDATE" + $($plusMinusText) + $($numberText) + ",dd>"
                
                    $dayNode.AppendChild($this.xmlDoc.CreateTextNode($dayText))
                    $monthNode.AppendChild($this.xmlDoc.CreateTextNode($monthText))
                    $yearNode.AppendChild($this.xmlDoc.CreateTextNode($yearText))
                }
            }
        }
        $this.xmlDoc.save($this.outputFilePath)
        (Get-Content $this.outputFilePath).replace('&lt;', '<').replace('&gt;', '>') | Set-Content $this.outputFilePath
        
    }


    [object] getSiblingNode($node, $siblingNodeName, $siblingNodeType){
        $parentNode = $node.ParentNode;
        $siblingNodes = $parentNode.ChildNodes
        $precedingSiblingNodes = $node.SelectNodes("./preceding-sibling::" + $siblingNodeName);

        $siblingNode = $this.getNode($node.SelectNodes("./preceding-sibling::" + $siblingNodeName),$siblingNodeName, $siblingNodeType)

        if($siblingNode -ne $null) {
            return $siblingNode
        }
        return $this.getNode($node.SelectNodes("./following-sibling::" + $siblingNodeName),$siblingNodeName, $siblingNodeType);
    } 

    [object] getNode($nodes, $nodeName, $nodeType){
        foreach($node in $nodes){
            if($node.NodeType -eq $nodeType -and $node.LocalName -eq $nodeName){
                return $node;
            }
        }
        return $null;
    }

}