$error.Clear()

<# --- email Parameter ---- 
Since subject and body is not declared under email parameter. It will be get decleared under each function. #>
$emailSMTPServer = ""
$emailRecipients = ""
$emailcc = ""
$emailFrom = ""

#Server Information
$servername = ""
$databasename = ""

<#This is Sql connection which connects to server grabs information from table under database and stores into $data.
------------------  SQL connection begins ---------------------- #>
try {
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server=$servername;Database=$databasename;Integrated Security=True"
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    <# we use the qurey here #>
    $SqlCmd.CommandText = $("Enter a SQL Query")
    $SqlCmd.Connection = $SqlConnection
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $SqlAdapter.fill($DataSet)   
}
catch [System.Management.Automation.MethodInvocationException]{
    $errormes = "There is an error connecting to $servername and to $databasename database. Here is the error: `n $error[0]"
    Send-MailMessage -From -To -Cc -Body $errormes -SmtpServer -Priority High
}
finally{
    $SqlConnection.Close()
    <# Storing the data in $data object #>
    $data = $dataset.Tables[0]
}
<#---------------------------- SQL connection ends -------------------------------- #>

#This command will count the row of $data and stores the value in $rows 
    $rows = ($data | Measure-Object).count

<#the if statement will check if it made connection to SQL by using $row value. If it is less then 1, it will alert by sending a email to the members.  #>
if ($rows -le 1) {
    write-host "Oh No. Something went wrong. There is error running this script." 

    <# declaring email subject and body. #>
    $emailerrorSubject = ""
    $emailerrorBody = ""
    <# The send-mailmessage will use email paramenter and will the email with high priority as we declar #>
    Send-MailMessage -From $emailFrom -To $emailRecipients -cc $emailcc -SmtpServer $emailSMTPServer -subject $emailerrorSubject -Body $emailerrorBody -Priority High
}

<#-----  First SQL connection begins ------ #>
else {
    <# storing the file path under $outfile to use in the script. #>
    $outfile = ""#Give a path to folder to save the text file
    write-host "Found Data"
    write-host "Moving data to the following file. Here is the location: $outfile"
    write-host "Processing..... Moving data to the file"
    <# This function will convert the data to CSV. It will remove quotes and will add bar as delimiter. Using the out-file function to export the file to $outfile location #>
    $data | ConvertTo-Csv -Delimiter "|" -NoTypeInformation | ForEach-Object{$_ -replace '"',""} | Out-File $outfile

    <# This will grab the count of the file and stores in $filesize. #>
    $filesize = (get-content $outfile).count

    #email Patameters
    $emailSubject = ""
    $emailBody = "The job ran sccuessful. The file ready to load. Please review the file. Here is a attachment of the file which has $filesize rows."
    Send-MailMessage -From $emailFrom -To $emailRecipients -cc $emailcc -SmtpServer $emailSMTPServer -subject $emailSubject -Body $emailBody -Priority Normal -Attachments $outfile
    write-host "Process is done. Email has sent to members."

    <# We use the IF statment here to make sure that data gets moved to the file. If it does not, it will alert the members. #>
    if($filesize -le 1) {
        $errorfilemove = "There was error moving the data to file after job ran"
        Write-Host "The data did not get move to the file. Sending email to members."
        Send-MailMessage -From $emailFrom -To $emailRecipients -cc $emailcc -SmtpServer $emailSMTPServer -subject $emailSubject -Body $errorfilemove -Priority High
    }
    else{
        Write-Host "Moved data to the file sccessfully."
    }
}
