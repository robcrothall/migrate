/************************************************************************/
/*					OS/2 DBM Reorganization Utility	 								*/
/************************************************************************/
/* Function		This procedure reorganizes all tables in the specified	*/
/*					database. The RUNSTATS command is also executed.			*/
/* Author		(c) Copyright Infoline AG 1991									*/
/*					Unterrietstrasse 6													*/
/*					CH-8152 Glattbrugg - Switzerland									*/
/*					Phone: ++41 1 810 97 77												*/
/*					Fax:   ++41 1 810 97 79												*/
/* History		V1.00 21/Sep/1991 Andy Brunner	Initial program version	*/
/************************************************************************/

/*======================================================================*/
/*	Initialize variables																  	*/
/*======================================================================*/

tempfile = 'DBMReorg.$$$'
temppath = 'C:\'

/*======================================================================*/
/*	Start function																		  	*/
/*======================================================================*/

StartFunction:

	/*-------------------------------------------------------------------*/
	/* Write title lines																	*/
	/*-------------------------------------------------------------------*/

	say
	say 'OS/2 DBM Reorganization Utility V1.00 (c) Copyright Infoline AG 1991'
 	say '--------------------------------------------------------------------'
	say

	/*-------------------------------------------------------------------*/
	/* Get command line arguments														*/
	/*-------------------------------------------------------------------*/

	parse arg dbname argx

	if dbname = '' | argx <> '' then do
		say 'Usage: DBMReorg DatabaseName'
		signal ExitProgram
	end

	/*-------------------------------------------------------------------*/
	/* Open database																		*/
	/*-------------------------------------------------------------------*/

	call OpenDatabase dbname

	/*-------------------------------------------------------------------*/
	/* Write temporary file with tablename and indexname	 					*/
	/*-------------------------------------------------------------------*/

	'@if exist' tempfile 'del' tempfile

	call OpenCursor 1, 'SELECT creator, name FROM sysibm.systables WHERE type = ''T'' AND creator <> ''SYSIBM'' ORDER BY creator, name'

	do while (FetchCursor(1, ':tablecreator, :tablename') = 0)

		/*----------------------------------------------------------------*/
		/* Locate all corresponding indexes for the found tables				*/
		/*----------------------------------------------------------------*/
		
		call OpenCursor 2, 'SELECT creator, name, uniquerule FROM sysibm.sysindexes WHERE tbcreator = ''' || strip(tablecreator) || ''' AND tbname = ''' || strip(tablename) || ''' ORDER BY uniquerule'
	
		do while (FetchCursor(2, ':indexcreator, :indexname, :indextype') = 0)

			if indextype = 'P' then
				leave

			if indextype = 'U' then
				leave
		end

		select
			when indextype = 'P' then
				indexrule = 'Primary'
			when indextype = 'U' then
				indexrule = 'Unique'
			when indextype = 'D' then
				indexrule = 'Duplicates'
			otherwise
				indexrule = 'N/A'
		end

		call CloseCursor 2 

		call lineout tempfile, tablename tablecreator indexrule indexname indexcreator

	end

	call CloseCursor 1 

	call lineout tempfile

	/*-------------------------------------------------------------------*/
	/* Commit SELECT statements														*/
	/*-------------------------------------------------------------------*/

	call ExecSQL 'COMMIT'

	/*-------------------------------------------------------------------*/
	/* Read temporary file and reorganize tables and perform RUNSTATS		*/
	/*-------------------------------------------------------------------*/

	say 'TableName          Creator  IndexRule      IndexName          Creator'
	say '---------------------------------------------------------------------'

	do while lines(tempfile) > 0

		inputline = linein(tempfile)

		parse var inputline tablename tablecreator indexrule indexname indexcreator

		say substr(tablename, 1, 18) substr(tablecreator, 1, 8) substr(indexrule, 1, 14) substr(indexname, 1, 18) substr(indexcreator, 1, 8)

		call ExecSQL 'LOCK TABLE' strip(tablecreator) || '.' || strip(tablename) 'IN EXCLUSIVE MODE'

		if indexrule = 'N/A' then
			call ExecDBS 'REORG TABLE' strip(tablecreator) || '.' || strip(tablename) 'IN' dbname 'USE' temppath
		else
			call ExecDBS 'REORG TABLE' strip(tablecreator) || '.' || strip(tablename) 'IN' dbname 'INDEX' strip(indexcreator) || '.' || strip(indexname) 'USE' temppath

		if indexrule = 'N/A' then
			call ExecDBS 'RUNSTATS ON TABLE' strip(tablecreator) || '.' || strip(tablename)
		else
			call ExecDBS 'RUNSTATS ON TABLE' strip(tablecreator) || '.' || strip(tablename) 'AND INDEXES ALL SHRLEVEL REFERENCE'

		call ExecSQL 'COMMIT'

	end

	call lineout tempfile


	'@del' tempfile

	/*-------------------------------------------------------------------*/
	/* Close database																		*/
	/*-------------------------------------------------------------------*/

	call CloseDatabase

ExitProgram:

	/*-------------------------------------------------------------------*/
	/* Terminate program																	*/
	/*-------------------------------------------------------------------*/

	exit
	
SqlError:

	/*-------------------------------------------------------------------*/
	/* Display SQL error message														*/
	/*-------------------------------------------------------------------*/

	say SQLMSG
	signal ExitProgram

/*======================================================================*/
/*	Open the database																	  	*/
/*======================================================================*/

OpenDatabase:

	/*-------------------------------------------------------------------*/
	/* Add the REXX SQL interface functions  										*/
	/*-------------------------------------------------------------------*/

	if RxFuncQuery('SQLDBS') <> 0 then do
		if RxFuncAdd('SQLDBS','SQLAR','SQLDBS') <> 0 then do
			say 'Error: Unable to load REXX SQL interface function SQLDBS.'
			signal ExitProgram
		end
	end

	if RxFuncQuery('SQLEXEC') <> 0 then do
		if RxFuncAdd('SQLEXEC','SQLAR','SQLEXEC') then do
			say 'Error: Unable to load REXX SQL interface function SQLEXEC.'
			signal ExitProgram
			end
		end

	/*-------------------------------------------------------------------*/
	/* Start Database Manager															*/
	/*-------------------------------------------------------------------*/

	call SQLDBS 'START DATABASE MANAGER'

	if SQLCA.SQLCODE <> -1026 & SQLCA.SQLCODE <> 0 then
		signal SqlError

	/*-------------------------------------------------------------------*/
	/* Open the database																	*/
	/*-------------------------------------------------------------------*/

	do forever

		call SQLDBS 'START USING DATABASE' arg(1)

		if SQLCA.SQLCODE <> 0 & SQLCA.SQLCODE <> -1015 then
			signal SqlError

		if SQLCA.SQLCODE = 0 then
			leave

		if SQLCA.SQLCODE = -1015 then do

			call SQLDBS 'RESTART DATABASE' arg(1)

			if SQLCA.SQLCODE <> 0 then
				signal SqlError
	
			iterate

		end

	end

	return result
		
/*======================================================================*/
/*	Close the database 																  	*/
/*======================================================================*/

CloseDatabase:

	/*-------------------------------------------------------------------*/
	/* Close the database																*/
	/*-------------------------------------------------------------------*/

	call SQLDBS 'STOP USING DATABASE'

	if SQLCA.SQLCODE <> 0 then
		signal SqlError

	/*-------------------------------------------------------------------*/
	/* Stop Database Manager															*/
	/*-------------------------------------------------------------------*/

	call SQLDBS 'STOP DATABASE MANAGER'

	if SQLCA.SQLCODE <> -1025 & SQLCA.SQLCODE <> 0 then
		signal SqlError

	/*-------------------------------------------------------------------*/
	/* Drop the REXX SQL interface functions										*/
	/*-------------------------------------------------------------------*/

	if RxFuncQuery('SQLDBS') == 0 then do
		if RxFuncDrop('SQLDBS') <> 0 then do
			say 'Error: Unable to drop REXX SQL interface function SQLDBS.'
			signal ExitProgram
		end
	end

	if RxFuncQuery('SQLEXEC') == 0 then do
		if RxFuncDrop('SQLEXEC') <> 0 then do
			say 'Error: Unable to drop REXX SQL interface function SQLEXEC.'
			signal ExitProgram
			end
		end

	return result
		
/*======================================================================*/
/*	Execute Database Services command 											  	*/
/*======================================================================*/

ExecDBS:

	call SQLDBS arg(1)

	if SQLCA.SQLCODE <> 0 then
		signal SqlError

	return result

/*======================================================================*/
/*	Execute SQL statement (Non-SELECT)											  	*/
/*======================================================================*/

ExecSQL:

	SqlStmt = arg(1)

	call SQLEXEC 'EXECUTE IMMEDIATE :SqlStmt'

	if SQLCA.SQLCODE <> 0 then
		signal SqlError

	return result

/*======================================================================*/
/*	Open SQL cursor	 																  	*/
/*======================================================================*/

OpenCursor:

	/*-------------------------------------------------------------------*/
	/* Declare the cursor																*/
	/*-------------------------------------------------------------------*/

	call SQLEXEC 'DECLARE c' || arg(1) 'CURSOR FOR s' || arg(1)

	if SQLCA.SQLCODE <> 0 then
		signal SqlError

	/*-------------------------------------------------------------------*/
	/* Prepare the SQL statement														*/
	/*-------------------------------------------------------------------*/

	SqlStmt = arg(2)

	call SQLEXEC 'PREPARE s' || arg(1) 'FROM :SqlStmt'

	if SQLCA.SQLCODE <> 0 then
		signal SqlError

	/*-------------------------------------------------------------------*/
	/* Open the cursor																	*/
	/*-------------------------------------------------------------------*/

	call SQLEXEC 'OPEN c' || arg(1)

	if SQLCA.SQLCODE <> 0 then
		signal SqlError

	return result

/*======================================================================*/
/*	Fetch SQL cursor	 																  	*/
/*======================================================================*/

FetchCursor:

	call SQLEXEC 'FETCH c' || arg(1) 'INTO' arg(2)
	
	if SQLCA.SQLCODE <> 0 & SQLCA.SQLCODE <> 100 then 
		signal SqlError

	if SQLCA.SQLCODE = 0 then
		return 0
	else
		return 1

/*======================================================================*/
/*	Close SQL cursor	 																  	*/
/*======================================================================*/

CloseCursor:

	call SQLEXEC 'CLOSE c' || arg(1)

	if SQLCA.SQLCODE <> 0 then
		signal SqlError

	return result

/************************************************************************/
/*	End of procedure																		*/
/************************************************************************/

