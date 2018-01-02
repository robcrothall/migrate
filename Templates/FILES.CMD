/* FILES.CMD - A PMREXX example */
Do Forever
     Say 'Please enter a file or directory name'
     Parse Pull filename
     if filename == '' then leave
     '@DIR' filename
End
