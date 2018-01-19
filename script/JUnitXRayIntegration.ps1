class JUnitXmlProcessor{
    [System.Xml.XmlDocument]$file
    [XrayTestEntityVo[]]$testVos = @()
    [XrayTestSetEntityVo[]]$testSetVos = @()
    [XrayTestPlanEntityVo]$testPlanVo
    [XrayTestExecutionEntityVo]$testExecutionVo

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
        $this.suiteName = $suiteNode.testsuitename
    }

    RootNodeHandler($root_node){
        $this.suiteName = $root_node.name
    }

    [XrayTestEntityVo] handleTestCaseNode($testCaseNode){
        $description = $testCaseNode.classname + ":" + $testCaseNode.name
        $summary = $description
        [XrayTestEntityVo]$testVo = [XrayTestEntityVo]::new($summary, $description, "Generic")
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

    [XrayTestEntityVo[]] handleIterationContainerNode($iterationContainerNode){
        Write-Host "Processing Iteration Container Node...."
        [XrayTestEntityVo[]]$testArr = @()
        [string]$activityType = "";
        foreach ($childNodeOfIterationContainer in $iterationContainerNode.ChildNodes) {
            $activityType = $childNodeOfIterationContainer.type
            if($activityType -eq 'test-case'){
                $testArr = $testArr + $this.handleTestCaseNode($childNodeOfIterationContainer)
            }
        }
        Write-Host "Found: " + $testArr.Count
        return $testArr
    }

    [XrayTestEntityVo[]] handleSmartFolderNode($smartFolderNode){
        Write-Host "Processing Smart Folder Node...."
        [XrayTestEntityVo[]]$testArr = @()
        [string]$activityType = "";
        foreach ($childNodeOfsmartFolder in $smartFolderNode.ChildNodes) {
            $activityType = $childNodeOfsmartFolder.type
            if($activityType -eq 'test-case'){
                $testArr = $testArr + $this.handleTestCaseNode($childNodeOfsmartFolder)
            } elseif ($activityType -eq 'iteration-container'){
                $testArr = $testArr + $this.handleIterationContainerNode($childNodeOfsmartFolder)
            } elseif ($activityType -eq 'smart-folder'){
                $testArr = $testArr + $this.handleSmartFolderNode($childNodeOfsmartFolder)
            }
        }
        Write-Host "Found: " $testArr.Count
        return $testArr
    }

    CreateTestSetVos(){
        $this.testSetVos = @() 
        $smartFolderNodes= $this.file.SelectNodes("//activity[@type='test-suite']/activity[@type='smart-folder']")
        [int]$count = 0
        $activtyType = ''
        foreach ($smartFolderNode in $smartFolderNodes) {
            Write-Host "Processing Next SmartFolder"
            $this.testSetVos = $this.testSetVos + [XrayTestSetEntityVo]::new($this.handleSmartFolderNode($smartFolderNode))
            Write-Host "Finished"
        }
    }

    SaveTestSetVos(){
        foreach ($testSetVo in $this.testSetVos) {
            Write-Host "Creating Test Set with " $testSetVo.tests.Count " tests..." 
            $testSetVo.create()
            Write-Host "Created Test Set with " $testSetVo.tests.Count " tests" 
        }
    }

    CreateTestVos(){
        $this.testVos = @()
        $testCaseNodes= $this.file.SelectNodes("/testsuite/testcase")
        [int]$count = 0
        foreach ($testCaseNode in $testCaseNodes) {
            Write-Host "Iterating Node: " $testCaseNode.LocalName
            $this.testVos = $this.testVos + $this.handleTestCaseNode($testCaseNode);
        }
        Write-Host "Tests Count: " +  $this.testVos.Count
    }

    SaveTestVos(){
        foreach ($testVo in $this.testVos) {
            $testVo.save()
            $testVo.changeWorkflowStatus(11);
        }
    }

    CreateTestPlanVo(){
        $this.testPlanVo = [XrayTestPlanEntityVo]::new($this.testVos, $this.testSetVos)
        
    }

    SaveTestPlanVo(){
        $this.testPlanVo.create()
    }

    CreateTestExecutionVo(){
        $this.testExecutionVo = [XrayTestExecutionEntityVo]::new($this.suiteName, $this.startDate, $this.endDate, $this.testPlanVo)
    }

    SaveTestExecutionVo(){
        $this.testExecutionVo.create()
    }
    
    [int]getTotalTestVos(){
        $count = 0
        $count = $this.testVos.Count;

        foreach($testSet in $this.testSetVos){
            $count = $count + $testSet.tests.Count
        }
        return $count
    }


    execute(){
        $this.CreateTestVos()
        #$this.CreateTestSetVos()
        $this.SaveTestVos()
        #$this.SaveTestSetVos()
        $this.CreateTestPlanVo();
        $this.SaveTestPlanVo()
        $this.CreateTestExecutionVo();
        $this.SaveTestExecutionVo()

    }
}

$vo = [JUnitXmlProcessor]::new([Constants]::reportFilePath)
