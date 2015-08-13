# Install and configure Tomcat, then pull down a sample tomcat war file (site).
# Tests run at the end to ensure the site is running on localhost port 8080

# Setup Parameters
$chocolateyExe = "C:\ProgramData\chocolatey\bin\choco.exe"
$tomcatBin = "C:\tools\apache-tomcat-8.0.23\bin"
$sampleApp = "C:\tools\apache-tomcat-8.0.23\webapps\sample"
$sampleAppCodeURL = "http://tomcat.apache.org/tomcat-6.0-doc/appdev/sample/sample.war"
$warHome = "C:\tools\apache-tomcat-8.0.23\webapps\sample.war"

# Test Parameters
$testURL = "http://localhost:8080/sample/"
$testDir = "C:\testdir\"
$testFile = "C:\testdir\test.txt"
$testHello = "Sample ""Hello, World"" Application"
$testHelloJsp = "<a href=""hello.jsp"">JSP page</a>"
$testHelloJspSvlt = "<a href=""hello"">servlet</a>"


#File Watcher Function - will need this to make sure the WAR gets unzipped
function WaitForFile($File)
{
    while(!(Test-Path $File))
    {
        Start-Sleep -s 10;
    }
}

#Test Function - test logic that can be called to test the newly running site
function Assert($Value)
{
    if($Value)
    {
        Write-Host -ForegroundColor GREEN "TRUE"
    }
    else
    {
        Write-Host -ForegroundColor RED "FALSE"
    }
}


# Install Chocolatey Packager Manager if Needed
$isChocolatey = Test-Path $chocolateyExe

if($isChocolatey -eq $True)
{
    Write-Host "Chocolatey is installed skipping to install Tomcat `n"
}
else
{
    $oldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path

    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

    $newPath=$oldPath+";C:\ProgramData\chocolatey\bin"

    SetItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
}

# Install Tomcat 8.0.23 if needed
$isTomcat = Test-Path $tomcatBin

if($isTomcat -eq $True)
{
    Write-Host "Tomcat is installed skipping to install sample app `n"
}
else
{
    Invoke-Expression "$chocolateyExe  install tomcat --confirm --force"
}

# Install Sample App if needed
$isSampleInstalled = Test-Path $sampleApp

if($isSampleInstalled -eq $True)
{
    Write-Host "Tomcat Sample App appears to be installed `n"
}
else
{
    Invoke-WebRequest $sampleAppCodeURL -OutFile $warHome
    WaitForFile($sampleApp)
    Write-Host ("Tomcat Sample App copied to: {0} `n" -f $warHome)
}

Write-Host "Test Install `n`n`n"

$testDirExists = Test-Path $testDir
if($testDirExists -eq $True)
{
    Write-Host ("{0} exists" -f $testDir)
    Write-Host ("Testing to see if {0} exists" -f $testFile)

    # Test Site
    $testFileExists = Test-Path $testFile

    if($testFileExists -eq $True)
    {
        Invoke-Expression "del $testFile"
    }

}
else
{
    New-Item -ItemType Directory -Force -Path $testDir
}

Invoke-WebRequest $testURL -OutFile $testFile

Write-Host "Test for Hello, World: "
Assert(Get-Content $testFile | Select-String $testHello -quiet)
Write-Host "Test for hello Jsp Link: "
Assert(Get-Content $testFile | Select-String $testHelloJsp -quiet)
Write-Host "Test for hello Servlett Link: "
Assert(Get-Content $testFile | Select-String $testHelloJspSvlt -quiet)

# Cleanup Test File
Invoke-Expression "del $testFile"
