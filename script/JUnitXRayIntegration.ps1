class AB{
    [XrayTestEntityVo[]]$testVos = @()
    [XrayTestSetEntityVo[]]$testSetVos = @()
    [XrayTestPlanEntityVo]$testPlanVo
    [XrayTestExecutionEntityVo]$testExecutionVo

    CreateTestEntityVos(){
        $this.testVos = $this.GetTestVos();
    }
    
    [XrayTestEntityVo[]] GetTestVos(){
        return $this.testVos
    }

    SaveTestEntityVos(){
        foreach ($testVo in $this.testVos) {
            $testVo.save()
            $testVo.changeWorkflowStatus(11);
        }
    }

    CreateTestSetEntityVos(){
        $this.testSetVos = $this.GetTestSetVos()
    }
    
    [XrayTestSetEntityVo[]] GetTestSetVos(){
        return $this.testSetVos;
    }

    SaveTestSetEntityVos(){
        foreach ($testSetVo in $this.testSetVos) {
            Write-Host "Creating Test Set with " $testSetVo.tests.Count " tests..." 
            $testSetVo.create()
            Write-Host "Created Test Set with " $testSetVo.tests.Count " tests" 
        }
    }

    CreateTestPlanEntityVo(){
        $this.testPlanVo = $this.GetTestPlanVo()
    }
    
    [XrayTestPlanEntityVo[]] GetTestPlanVo(){
        return [XrayTestPlanEntityVo]::new($this.testVos, $this.testSetVos);
    }

    SaveTestPlanEntityVo(){
        $this.testPlanVo.create()
    }

    CreateTestExecutionEntityVo(){
        $this.testExecutionVo = $this.GetTestExecutionEntityVo()
    }
    
    [XrayTestExecutionEntityVo] GetTestExecutionEntityVo(){
        return [XrayTestExecutionEntityVo]::new($this.suiteName, $this.startDate, $this.endDate, $this.testPlanVo);
    }

    SaveTestExecutionVo(){
        $this.testExecutionVo.create()
    }
}

class JUnitXmlProcessor : AB {
    [System.Xml.XmlDocument]$file
    [string]$startDate;
    [string]$endDate;
    [string]$suiteName;

    JUnitXmlProcessor($filePath){
        [System.Xml.XmlDocument]$this.file = new-object System.Xml.XmlDocument
        $this.file.load($filePath)
        $this.init()
    }

    init(){
        $this.PopulateSuiteInfo()
    }

    PopulateSuiteInfo(){
        $this.RootNodeHandler($this.file.SelectNodes("/testsuite"))
    }

    TestSuiteNodeHandler($suiteNode){
        $this.suiteName = $suiteNode.name
    }

    [XrayTestEntityVo] handleTestCaseNode($testCaseNode){
        $description = $testCaseNode.classname + ":" + $testCaseNode.name
        $summary = $description
        [XrayTestEntityVo]$testVo = [XrayTestEntityVo]::new()
        $testVo.summary = $summary
        $testVo.description = $description
        $comment = $this.getComment($testCaseNode)
        $testVo.setStatus($this.getStatus($testCaseNode))
        $testVo.setComment($comment)

        return $testVo
    }

    [string] getStatus($test_case_node){
          $comment = $null;
          $hasChildNodes = $test_case_node.HasChildNodes;
          
          if($hasChildNodes) {
            foreach($childNode in $test_case_node.ChildNodes){
                $childNodeName = $childNode.LocalName
                if($childNodeName -eq 'failure'){
                    return 'FAIL'
                } elseif ($childNodeName -eq 'error'){
                    return 'FAIL'
                } elseif ($childNodeName -eq 'skipped'){
                    return 'TODO'
                } else {
                    Write-Host "Status need to be defined"
                    return 'UNKNOWN'
                }
            }
            return 'UNKNOWN'
          } else {
            return 'PASS'
          }
          
    }
    
    [string] getComment($test_case_node){
          $comment = $null;
          $hasChildNodes = $test_case_node.HasChildNodes;

          if($hasChildNodes) {
            foreach($childNode in $test_case_node.ChildNodes){
                $childNodeName = $childNode.LocalName
                if($childNodeName -eq 'failure'){
                    $comment = $childNode.InnerText
                } elseif ($childNodeName -eq 'error'){
                    $comment = $childNode.InnerText
                } elseif ($childNodeName -eq 'skipped'){
                    $comment = 'Skipped'
                }
            }
          } else {
            $comment = 'Execution Successful.'
          }
          Write-Host "Comment " $comment
          return $comment
    }

    [XrayTestEntityVo[]] GetTestVos(){
        $testVos = @()
        $testCaseNodes= $this.file.SelectNodes("/testsuite/testcase")
        [int]$count = 0
        foreach ($testCaseNode in $testCaseNodes) {
            Write-Host "Iterating Node: " $testCaseNode.LocalName
            $testVos = $testVos + $this.handleTestCaseNode($testCaseNode);
        }
        Write-Host "Tests Count: " +  $this.testVos.Count
        return $testVos
    }

    [XrayTestExecutionEntityVo] GetTestExecutionEntityVo(){
        return [XrayTestExecutionEntityVo]::new($this.suiteName, $this.startDate, $this.endDate, $this.testPlanVo);
    }

    execute(){
        $this.CreateTestVos()
        $this.SaveTestVos()
        $this.CreateTestPlanVo();
        $this.SaveTestPlanVo()
        $this.CreateTestExecutionVo();
        $this.SaveTestExecutionVo()

    }
}

$vo = [JUnitXmlProcessor]::new([Constants]::reportFilePath)
