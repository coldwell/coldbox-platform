<!-----------------------------------------------------------------------********************************************************************************Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corpwww.coldboxframework.com | www.luismajano.com | www.ortussolutions.com********************************************************************************Author: Luis MajanoDate:   September 27, 2005Description: This is the framework's logger object. It performs all necessary			 loggin procedures.Modifications:09/25/2005 - Created the template.10/13/2005 - Updated the reqCollection to the request scope.12/18/2005 - Using mailserverSettings from config.xml now, fixed structnew for default to logError12/20/2005 - Bug on spaces for log files.02/16/2006 - Fixes for subjects06/28/2006 - Updates for coldbox07/12/2006 - Tracer updates01/20/2007 - Update for new bean types and formatting.02/10/2007 - Updated for 1.2.0-----------------------------------------------------------------------><cfcomponent name="logger"			 hint="This is the frameworks logger object. It is used for all logging facilities."			 extends="coldbox.system.plugin"			 output="false"			 cache="true"><!------------------------------------------- CONSTRUCTOR ------------------------------------------->	<cffunction name="init" access="public" returntype="logger" hint="Constructor" output="false">		<cfargument name="controller" type="any" required="true">		<cfset super.Init(arguments.controller) />		<!--- Setup Plugin Properties --->		<cfset setpluginName("Logger")>		<cfset setpluginVersion("1.1")>		<cfset setpluginDescription("This plugin is used for logging methods and facilities.")>				<!---  SETUP LOGGER PROPERTIES --->				<!--- log name without extension --->		<cfset setLogFileName( URLEncodedFormat(replace(replace(getSetting("AppName")," ","","all"),".","_","all")) )>				<!--- The full absolute path of the log file --->		<cfif settingExists("ColdboxLogsLocation")>			<cfset setlogFullPath( getSetting("ColdboxLogsLocation") )>		<cfelse>			<cfset setlogFullPath('')>		</cfif>				<!--- Available valid severities --->		<cfset instance.validSeverities = "information|fatal|warning|error|debug">		<!--- Lock Name --->		<cfset instance.lockName = getController().getAppHash() & "_LOGGER_OPERATION">		<!--- Return --->		<cfreturn this>	</cffunction><!------------------------------------------- PUBLIC ------------------------------------------->	<!--- ************************************************************* --->		<cffunction name="tracer" access="Public" hint="Log a trace message to the debugger panel" output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="message"    type="string" required="Yes" hint="Message to Send" >		<cfargument name="ExtraInfo"  required="No" default="" type="any" hint="Extra Information to dump on the trace">		<!--- ************************************************************* --->		<cfscript>			var tracerEntry = StructNew();			var event = controller.getRequestService().getContext();			var oSessionStorage = getPlugin("sessionStorage");			var tracerStack = "";						/* Verify if the tracer stack exists, else create */			if ( not oSessionStorage.Exists("fw_tracerStack") ){				oSessionStorage.setVar("fw_tracerStack", ArrayNew(1) );			}						/* Local Reference */			tracerStack = oSessionStorage.getVar("fw_tracerStack");						/* Insert Message & Info to entry */			StructInsert(tracerEntry,"message", arguments.message);						/* Extra Info Operations */			if ( not isSimpleValue(arguments.ExtraInfo) )				StructInsert(tracerEntry,"ExtraInfo", duplicate(arguments.ExtraInfo));			else				StructInsert(tracerEntry,"ExtraInfo", arguments.ExtraInfo);						/* Append Entry to Array */			ArrayAppend(tracerStack,tracerEntry);						/* Store in Flash Session Variable */			oSessionStorage.setVar("fw_tracerStack", tracerStack );		</cfscript>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="logErrorWithBean" access="public" hint="Log an error into the framework using a coldbox exceptionBean" output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="ExceptionBean" 	type="any" 	required="yes">		<!--- ************************************************************* --->		<!--- Initialize variables --->		<cfset var Exception = arguments.ExceptionBean>		<cfset var BugReport = "">		<cfset var logSubject = "">		<cfset var errorText = "">		<cfset var arrayTagContext = "">		<cfset var myStringBuffer = "">		<cftry>			<cfif getSetting("EnableColdfusionLogging") or getSetting("EnableColdboxLogging")>				<!--- Log Entry in the Logs --->				<cfif isStruct(Exception.getExceptionStruct())>					<cfset myStringBuffer = getPlugin("StringBuffer").setup(BufferLength=500)>					<cfif Exception.getType() neq  "">						<cfset myStringBuffer.append( "CFErrorType=" & Exception.getType() & chr(13) )>					</cfif>					<cfif Exception.getDetail() neq  "">						<cfset myStringBuffer.append("CFDetails=" & Exception.getDetail() & chr(13) )>					</cfif>					<cfif Exception.getMessage() neq "">						<cfset myStringBuffer.append("CFMessage=" & Exception.getMessage() & chr(13) )>					</cfif>					<cfif Exception.getStackTrace() neq "">						<cfset myStringBuffer.append("CFStackTrace=" & Exception.getStackTrace() & chr(13) )>					</cfif>					<cfif Exception.getTagContextAsString() neq "">						<cfset myStringBuffer.append("CFTagContext=" & Exception.getTagContextAsString() & chr(13) )>					</cfif>				</cfif>				<!--- Log the Entry --->				<cfset logEntry("error","Custom Error Message: #Exception.getExtraMessage()#",myStringBuffer.getString() )>			</cfif>			<cfcatch type="any"><!---Silent Failure---></cfcatch>		</cftry>		<!--- Check if Bug Reports are Enabled, then send Email Bug Report --->		<cfif getSetting("EnableBugReports") and getSetting("BugEmails") neq "">			<cftry>			<!--- Save the Bug Report --->			<cfset BugReport = controller.getService("exception").renderEmailBugReport(arguments.ExceptionBean)>			<!--- Setup The Subject --->			<cfset logSubject = "#getSetting("Codename",1)# Bug Report: #getSetting("Environment")# - #getSetting("appname")#">			<!--- Check for Custom Mail Settings or use CFMX Administrator Settings --->			<cfif getSetting("MailServer") neq "" and 				  getSetting("MailUsername") neq "">				<!--- Mail New Bug --->				<cfmail to="#getSetting("BugEmails")#"						from="#getSetting("OwnerEmail")#"						subject="#logSubject#"						type="html"						server="#getSetting("MailServer")#"						username="#getSetting("MailUsername")#"						password="#getSetting("MailPassword")#">#BugReport#</cfmail>			<cfelse>				<!--- Mail New Bug --->				<cfmail to="#getSetting("BugEmails")#"						from="#getSetting("OwnerEmail")#"						subject="#logSubject#"						type="html">#BugReport#</cfmail>			</cfif>				<cfcatch type="any"><!---Silent Failure---></cfcatch>			</cftry>		</cfif>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="logError" access="public" hint="Log an error into the framework using arguments. Facade to logErrorWithBean." output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="Message" 			type="string" 	required="yes">		<cfargument name="ExceptionStruct" 	type="any"  	required="no" default="#StructNew()#" hint="The CF cfcatch structure.">		<cfargument name="ExtraInfo"  		type="any"    	required="no" default="">		<!--- ************************************************************* --->		<cfset logErrorWithBean(CreateObject("component","coldbox.system.beans.exceptionBean").init(arguments.ExceptionStruct,arguments.message,arguments.ExtraInfo))>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="logEntry" access="public" hint="Log a message to the Coldfusion/Coldbox Logging Facilities if enabled via the config" output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="Severity" 		type="string" 	required="yes">		<cfargument name="Message" 			type="string"  	required="yes" hint="The message to log.">		<cfargument name="ExtraInfo"		type="string"   required="no"  default="" hint="Extra information to append.">		<!--- ************************************************************* --->		<!--- Check for Severity via RE --->		<cfif not reFindNoCase("^(#getValidSeverities()#)$",arguments.Severity)>			<cfthrow type="Framework.plugins.logger.InvalidSeverityException" message="The severity you entered: #arguments.severity# is an invalid severity. Valid severities are #getValidSeverities()#.">		</cfif>		<!--- Check for Coldfusion Logging --->		<cfif getSetting("EnableColdfusionLogging")>			<!--- Coldfusion Log Entry --->			<cflog type="#trim(lcase(arguments.severity))#"				   text="#arguments.message# & #chr(13)# & ExtraInfo: #arguments.ExtraInfo#"				   file="#getLogFileName()#">		</cfif>		<!--- Check For Coldbox Logging --->		<cfif getSetting("EnableColdboxLogging")>			<!--- Check for Log File --->			<cfif not FileExists(getlogFullPath())>				<!--- File has been deleted, reinit the log location --->				<cfset initLogLocation(false)>				<!--- Log the occurrence recursively--->				<cfset logEntry("warning","Log Location had to be reinitialized. The file: #getLogFullPath()# was not found when trying to do a log.")>			</cfif>			<!--- Check Rotation --->			<cfset checkRotation()>			<cflock type="exclusive" name="#getLockName()#" timeout="120">				<cftry>					<cffile action="append" 							addnewline="true" 							file="#getlogFullPath()#" 							output="#formatLogEntry(arguments.severity,arguments.message,arguments.extraInfo)#"							charset="#getSetting("LogFileEncoding",1)#">					<cfcatch type="any">						<cfthrow type="Framework.plugins.logger.WritingEntryException" message="An error occurred writing an entry to the log file." detail="#cfcatch.Detail#<br>#cfcatch.message#">					</cfcatch>				</cftry>			</cflock>		</cfif>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="initLogLocation" access="public" hint="Initialize the ColdBox log location." output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="firstRunFlag" default="true" type="boolean" required="false" hint="This is true when ran from the configloader, to run the setupLogLocationVariables() method.">		<!--- ************************************************************* --->		<cfset var FileWriter = "">		<cfset var InitString = "">		<cfset var oFileUtilities = "">		<cflock name="#getlockName()#" type="exclusive" timeout="120">			<!--- Determine First Run --->			<cfif arguments.firstRunFlag>				<!--- Setup Log Location Variables --->				<cfset setupLogLocationVariables()>			</cfif>			<!--- Create Log File if It does not exist and initialize it. --->			<cfif not fileExists(getLogFullPath())>				<cfset oFileUtilities = getPlugin("Utilities")>				<cftry>					<!--- Create Log File --->					<cfset oFileUtilities.createFile(getLogFullPath())>					<!--- Check if we can write to the file --->					<cfif not oFileUtilities.FileCanWrite(getLogFullPath())>						<cfthrow type="Framework.plugins.logger.LogFileNotWritableException" message="The log file: #getLogFullPath()# is not a writable file. Please check your operating system's permissions.">					</cfif>					<cfcatch type="any">						<cfthrow type="Framework.plugins.logger.CreatingLogFileException" message="An error occurred creating the log file at #getLogFullPath()#." detail="#cfcatch.Detail#<br>#cfcatch.message#">					</cfcatch>				</cftry>				<cftry>					<!---						Log Format						"[severity]" "[ThreadID]" "[Date]" "[Time]" "[Application]" "[Message]"					--->					<cfset InitString = '"Severity","ThreadID","Date","Time","Application","Message"' & chr(13) & chr(10) & formatLogEntry("information","The log file has been initialized successfully by ColdBox.","Log file: #getLogFullPath()#; Encoding: #getSetting("LogFileEncoding",1)#")>										<cffile action="append" 							addnewline="true" 							file="#getlogFullPath()#" 							output="#InitString#"							charset="#getSetting("LogFileEncoding",1)#">												<cfcatch type="any">						<cfthrow type="Framework.plugins.logger.WritingFirstEntryException" message="An error occurred writing the first entry to the log file." detail="#cfcatch.Detail#<br>#cfcatch.message#">					</cfcatch>				</cftry>			</cfif>		</cflock>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="removeLogFile" access="public" hint="Removes the log file" output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="reinitializeFlag" required="false" default="true" type="boolean" hint="Flag to reinitialize the log location or not." >		<!--- ************************************************************* --->		<cflock name="#getLockName()#" type="exclusive" timeout="120">			<cffile action="delete" file="#getLogFullPath()#">		</cflock>		<cfif arguments.reinitializeFlag>			<cfset initLogLocation(false)>		</cfif>	</cffunction>	<!--- ************************************************************* ---><!------------------------------------------- PUBLIC ACCESSOR/MUTATORS ------------------------------------------->	<!--- ************************************************************* --->	<cffunction name="setLogFileName" access="public" hint="Set the logfilename" output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="filename" 		type="string" 	required="yes" hint="The filename to set">		<!--- ************************************************************* --->		<cfset instance.logfilename = arguments.filename>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="getLogFileName" access="public" hint="Get the logfilename" output="false" returntype="string">		<cfreturn instance.logfilename >	</cffunction>	<!--- ************************************************************* --->	<cffunction name="setlogFullPath" access="public" hint="Set the logFullPath" output="false" returntype="void">		<!--- ************************************************************* --->		<cfargument name="logFullPath" 		type="string" 	required="yes" hint="The logFullPath to set">		<!--- ************************************************************* --->		<cfset instance.logFullPath = arguments.logFullPath>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="getlogFullPath" access="public" hint="Get the logFullPath" output="false" returntype="string">		<cfreturn instance.logFullPath >	</cffunction>	<!--- ************************************************************* --->	<cffunction name="getvalidSeverities" access="public" hint="Get the validSeverities" output="false" returntype="string">		<cfreturn instance.validSeverities >	</cffunction>	<!--- ************************************************************* --->		<cffunction name="getlockName" access="public" output="false" returntype="string" hint="Get lockName">		<cfreturn instance.lockName/>	</cffunction>		<!--- ************************************************************* --->	<!------------------------------------------- PRIVATE ------------------------------------------->	<!--- ************************************************************* --->	<cffunction name="formatLogEntry" access="private" hint="Format a log request into the specified entry format." output="false" returntype="string">		<!--- ************************************************************* --->		<cfargument name="Severity" 		type="string" 	required="yes" hint="error|warning|info">		<cfargument name="Message" 			type="string"  	required="yes" hint="The message to log.">		<cfargument name="ExtraInfo"		type="string"   required="no" default="" hint="Extra information to append.">		<!--- ************************************************************* --->		<cfscript>			var LogEntry = "";			//Manipulate entries			arguments.severity = trim(lcase(arguments.severity));			arguments.message = trim(arguments.message) & trim(arguments.extrainfo);			arguments.message = replace(arguments.message,'"','""',"all");			arguments.message = replace(arguments.message,"#chr(13)##chr(10)#",'  ',"all");			arguments.message = replace(arguments.message,chr(13),'  ',"all");			LogEntry = '"#arguments.Severity#","logger-plugin","#dateformat(now(),"MM/DD/YYYY")#","#timeformat(now(),"HH:MM:SS")#",,"#arguments.message#"';			//return formatted entry			return logEntry;		</cfscript>			</cffunction>	<!--- ************************************************************* --->	<cffunction name="setupLogLocationVariables" access="private" hint="Setup the log location variables." output="false" returntype="void">		<!--- The Default Full log directory path --->		<cfset var DefaultLogDirectory = getSetting("ApplicationPath",1) & getSetting("OSFileSeparator",1) & getSetting("DefaultLogDirectory",1)>		<!--- The absolute test Path --->		<cfset var absTestPath = getPlugin("Utilities").getAbsolutePath(getSetting("ColdboxLogsLocation"))>		<!--- The local relative test path --->		<cfset var TestPath = getSetting("ApplicationPath",1) & getSetting("OSFileSeparator",1) & getSetting("ColdboxLogsLocation")>		<!--- Test EstablishedLogLocationpath --->		<cfset var EstablishedLogLocationpath = "">				<!--- Test for no setting defined, but logging enabled. --->		<cfif getSetting("ColdboxLogsLocation") eq "">			<cfset createDefaultLogDirectory()>			<cfset EstablishedLogLocationpath = DefaultLogDirectory>		<!--- Test for local relative test path --->		<cfelseif directoryExists( TestPath )>			<cfset EstablishedLogLocationpath = TestPath>		<cfelseif directoryExists(absTestPath)>			<cfset EstablishedLogLocationpath = absTestPath>		<!--- AbsPath did not exist --->		<cfelse>			<cfdirectory action="create" directory="#absTestPath#">			<cfset EstablishedLogLocationpath = absTestPath>		</cfif>				<!--- Finalize the path --->		<cfset EstablishedLogLocationpath = EstablishedLogLocationpath & getSetting("OSFileSeparator",1) & getLogFileName() & ".log">				<!--- Then set the complete log path and save. --->		<cfset setSetting("ExpandedColdboxLogsLocation", EstablishedLogLocationpath)>		<cfset setlogFullPath(EstablishedLogLocationpath)>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="createDefaultLogDirectory" access="private" hint="Creates the default log directory." output="false" returntype="void">		<cfset var DefaultLogDirectory = getSetting("ApplicationPath",1) & getSetting("OSFileSeparator",1) & getSetting("DefaultLogDirectory",1)>		<!--- Check if the directory already exists --->		<cfif not directoryExists(DefaultLogDirectory)>			<cfdirectory action="create" directory="#DefaultLogDirectory#">		</cfif>	</cffunction>	<!--- ************************************************************* --->	<cffunction name="checkRotation" access="private" hint="Checks the log file size. If greater than framework's settings, then zip and rotate." output="false" returntype="void">		<cfset var zipFileName = "">		<cfset var qArchivedLogs = "">		<cfset var ArchiveToDelete = "">				<!--- Verify FileSize --->		<cfif getPlugin("Utilities").FileSize(getlogFullPath()) gt (getSetting("LogFileMaxSize",1) * 1024)>			<cftry>								<!--- How Many Log Files Do we Have --->				<cfdirectory action="list" 					 filter="#getLogFileName()#*.zip" 					 name="qArchivedLogs" 					 directory="#getDirectoryFromPath(getlogFullPath())#" 					 sort="DATELASTMODIFIED" >								<!--- Zip Log File --->				<cflock name="#getlockName()#" type="exclusive" timeout="120">					<!--- Should I remove log Files --->					<cfif qArchivedLogs.recordcount gte getSetting("LogFileMaxArchives",1)>						<cfset ArchiveToDelete = qArchivedLogs.directory[1] & getSetting("OSFileSeparator",1) & qArchivedLogs.name[1] >						<!--- Remove the oldest one --->						<cffile action="delete" file="#ArchiveToDelete#">					</cfif>					<!--- Set the name of the archive --->					<cfset zipFileName =  getDirectoryFromPath(getlogFullPath()) & getLogFileName() & "." & createUUID() & ".zip">					<!--- Zip it --->					<cfset getPlugin("zip").AddFiles(zipFileName,getlogFullPath(),"","",false,9,false )>				</cflock>								<!--- Clean & reinit Log File --->				<cfset removeLogFile(true)>								<!--- Trap Any errors --->				<cfcatch type="any">					<cfset logEntry("error","Could not zip and rotate log files.","#cfcatch.Detail# #cfcatch.Message#")>				</cfcatch>			</cftry>		</cfif>	</cffunction>	<!--- ************************************************************* ---></cfcomponent>