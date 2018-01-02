/* Print a file with a header page */
parse arg fn;
say 'Consolidated Share Registrars Limited' > pr.hed
'copy pr.hed lpt1:';
'print' fn;
