# BackupFiles.ps1 
# Greg Lyon - July 2006 
 
# ----------------------------------------------------- 
 
function BackupFolder 
{ 
    param( [object] $objSrcFolder, [object] $objDstFolder) 
 
    $strSrcFolder = $objSrcFolder.Path 
    $strDstFolder = $objDstFolder.Path 
 
    $colSrcFiles = $objSrcFolder.Files 
    $colDstFiles = $objDstFolder.Files 
 
    foreach ($objSrcFile in $colSrcFiles) 
    { 
        $strSrcFile = $strSrcFolder + "\" + $objSrcFile.Name 
        $strDstFile = $strDstFolder + "\" + $objSrcFile.Name 
        if($FSO.FileExists($strDstFile)) 
        { 
            $objDstFile = $FSO.GetFile($strDstFile) 
            $dtSrcFile = $objSrcFile.DateLastModified 
            $dtDstFile = $objDstFile.DateLastModified 
            $iSec = (New-TimeSpan -Start $dtDstFile -End $dtSrcFile).TotalSeconds 
            if($iSec -gt 2) # allow 2 seconds difference for CD, network drive etc. 
            { 
                $FSO.CopyFile($strSrcFile, $strDstFile, $true) 
                Write-Host "Copied file $strSrcFile to $strDstFile" 
                $script:iCopyCount++ 
            } 
        } 
        else 
        { 
            $FSO.CopyFile($strSrcFile, $strDstFile, $true) 
            Write-Host "Copied file $strSrcFile to $strDstFile" 
            $script:iCopyCount++ 
        } 
    } 
 
    foreach($objDstFile In $colDstFiles) 
    { 
        $strDstFile = $objDstFile.Path 
        $strSrcFile = $strSrcFolder + "\" + $objDstFile.Name 
 
        if( -not $FSO.FileExists($strSrcFile)) 
        { 
            $FSO.DeleteFile($strDstFile) 
            Write-Host "Deleted file $strDstFile" 
            $script:iDestDeletedCount++ 
        } 
    } 
 
    DoSubFolders $objSrcFolder $objDstFolder 
} 
 
# ----------------------------------------------------- 
 
function DoSubFolders 
{ 
    param([object] $objSrcFolder, [object] $objDstFolder) 
 
    $colSrcSubFolders = $objSrcFolder.SubFolders 
 
    foreach($objSrcSubFolder in $colSrcSubFolders) 
    { 
        $strSrcSubFolder = $objSrcSubFolder.Path 
        $strDstSubFolder = $strSrcSubFolder.Replace($strSourceFolder, $strDestinationFolder) 
        if( -not $FSO.FolderExists($strDstSubFolder)) 
        { 
            $FSO.CreateFolder($strDstSubFolder) 
            Write-Host "Created folder $strDstSubFolder" 
        } 
        $objDstSubFolder = $FSO.GetFolder($strDstSubFolder) 
        BackupFolder $objSrcSubFolder $objDstSubFolder 
        DoSubFolders $objSrcSubFolder $objDstSubFolder 
    } 
} 
# ----------------------------------------------------- 
function WaitKey 
{ 
    param( [String] $strPrompt = "Press any key to continue ... ") 
    Write-Host 
    Write-Host $strPrompt -NoNewline 
    $key = [Console]::ReadKey($true) 
    Write-Host 
} 
 
# ----------------------------------------------------- 
# main 
 
$strSourceFolder      = "D:\PS1" 
$strDestinationFolder = "E:\Drive_D_Copy\PS1" 
 
$iCopyCount = 0 
$iDestDeletedCount = 0 
 
Write-Host 
Write-Host "Backing up " -NoNewline -ForegroundColor "White" 
Write-Host $strSourceFolder -ForegroundColor "Cyan" -NoNewline 
Write-Host " to " -NoNewline -ForegroundColor "White" 
Write-Host $strDestinationFolder -ForegroundColor "Cyan" 
Write-Host 
 
$FSO = New-Object -COM Scripting.FileSystemObject 
 
if( -not $FSO.FolderExists($strSourceFolder) ) 
{ 
    Write-Host "Error: source folder does not exist!" -ForegroundColor "Red" 
    Write-Host 
    Write-Host "Exiting script" 
    WaitKey "Press any key to exit ... " 
    exit 
} 
 
if( -not $FSO.FolderExists($strDestinationFolder) ) 
{ 
    Write-Host "Warning: destination folder does not exist" 
    $p = Read-Host "Create folder and continue? " 
    Write-Host 
    if( $p.Substring(0, 1).ToUpper() -eq "Y" ) 
    { 
        $FSO.CreateFolder($strDestinationFolder) 
    } 
    else 
    { 
        Write-Host "Exiting script" 
        WaitKey "Press any key to exit ... " 
        exit 
    } 
} 
 
$objSourceFolder = $FSO.GetFolder($strSourceFolder) 
$objDestinationFolder = $FSO.GetFolder($strDestinationFolder) 
 
BackupFolder $objSourceFolder $objDestinationFolder 
 
if( ($iCopyCount -eq 0) -and ($iDestDeletedCount -eq 0) ) 
{ 
    Write-Host 
    Write-Host "Folders are synchronized" -ForegroundColor "magenta" 
} 
else 
{ 
    Write-Host 
    Write-Host $iCopyCount "files copied from source to destination" -ForegroundColor "magenta" 
    Write-Host $iDestDeletedCount "orphaned destination files deleted" -ForegroundColor "magenta" 
} 
 
WaitKey "Press any key to exit ... " 
 
# ----------------------------------------------------- 
 