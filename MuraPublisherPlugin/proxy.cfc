<cfcomponent output="false">

	<cfset variables.instanceKey = createUUID() />

	<cfset variables.configBean=application.configBean />
	<cfset variables.dsn=application.configBean.getDatasource() />
	
	<cfset variables.pluginConfig = application.pluginManager.getConfig( listLast(listLast(getDirectoryFromPath(getCurrentTemplatePath()),variables.configBean.getFileDelim()),"_") ) />
	<cfset variables.libPackage = variables.pluginConfig.getApplication().getValue( "libPackage" ) />

	<cffunction name="ping" access="remote" returntype="boolean" output="false">
		<cfreturn true />
	</cffunction>
	
	<cffunction name="register" access="remote" returntype="any" output="false">
		<cfargument name="subscriberURL" type="string" required="true" />
		<cfargument name="subscriberId" type="string" required="true" />
		
		<!--- check to see if has content --->
		<cfset var local = structNew() />
		<cfset local.results = structNew() />

		<!--- lock the request (race conditioning) --->
		<cflock type="exclusive" timeout="30">

			<!--- attempt to get the registrar --->
			<cfset local.registrar = variables.libPackage.registrarDAO.readBySubscriberURL( arguments.subscriberURL ) />
			
			<!--- if new then pass in subscriber values --->
			<cfif local.registrar.get( "isNew" )>
			
				<!--- set return content --->
				<cfset local.results.status = "SUCCESS" />
				<cfset local.results.message = "Registered" />
				<!--- get setup information for registration purposes --->
				<cfset local.results.setup = getSetupInformation() />
			
				<cfset local.registrar.set( "subscriberURL", arguments.subscriberURL ) />
				<cfset local.registrar.set( "subscriberID", arguments.subscriberID ) />
				<cfset local.registrar.set( "status", "not approved" ) />
				<!--- save registrar --->
				<cfset variables.libPackage.registrarDAO.save( local.registrar ) />
			
			<cfelse>
				
				<!--- set the message --->
				<cfset local.results.status = "ERROR" />
				<cfset local.results.message = "Already Registered" />
			
			</cfif>
			
		</cflock>
		
		<!--- return content --->
		<cfreturn local.results />
	</cffunction>
	
	<cffunction name="status" access="remote" returntype="string" output="false">
		<cfargument name="subscriberURL" type="string" required="true" />
		<cfargument name="subscriberId" type="string" required="true" />
		
		<cfset var local = structNew() />
		
		<!--- read out the record --->
		<cfset local.registrar = variables.libPackage.registrarDAO.readBySubscriberURL( arguments.subscriberURL ) />
				
		<!--- return the status --->
		<cfreturn local.registrar.get( "status" ) />
	</cffunction>
	
	<cffunction name="activeContent" access="remote" returntype="string" output="false">
	
		<cfset var local = structNew() />
	
		<!--- get content from publisher --->
		<cfinvoke webservice="http://skunkworks.local.mura.com:8600/MuraProxy.cfc?wsdl"
			method="login"
			returnVariable="local.login">
			<cfinvokeargument name="username" value="remoteUser">
			<cfinvokeargument name="password" value="remoteUser">
			<cfinvokeargument name="siteID" value="skunkworks">
		</cfinvoke>
	
		<cfset local.args = structNew() />
		<cfset local.args.siteId = "skunkworks" />
		<cfinvoke webservice="http://skunkworks.local.mura.com:8600/MuraProxy.cfc?wsdl"
			method="call"
			returnVariable="local.webserviceResults">
			<cfinvokeargument name="serviceName" value="publisher">
			<cfinvokeargument name="methodName" value="getActiveContent">
			<cfinvokeargument name="authToken" value="#local.login#">
			<cfinvokeargument name="args" value="#local.args#" />
		</cfinvoke>
	
	</cffunction>
	
	<cffunction name="getSetupInformation" access="private" returntype="any" output="false">
		
		<cfset var setup = structNew() />

		<!--- mura proxy --->		
		<cfset setup[ "muraProxyURL" ] = "#buildMuraURLByCGI()#MuraProxy.cfc" />
		<cfif len( variables.pluginConfig.getSetting( "muraProxyURL" ) )>
			<cfset setup[ "muraProxyURL" ] = variables.pluginConfig.getSetting( "muraProxyURL" ) />
		</cfif>
		<!--- publisher proxy --->
		<cfset setup[ "publisherProxyURL" ] = "#buildMuraURLByCGI()#plugins/#variables.pluginConfig.getDirectory()#/proxy.cfc" />
		
		<cfreturn setup />
	</cffunction>
	<cffunction name="buildMuraURLByCGI" access="public" returntype="string" output="false">
		
		<cfset var urlStr = "" />
		
		<!--- start string --->
		<cfset urlStr = "http://" />
		<cfif findNoCase( "https", cgi.server_protocol)>
			<cfset urlStr = "https://" />
		</cfif>
		
		<!--- get host --->
		<cfset urlStr = urlStr & cgi.http_host & "/" & application.configBean.getContext() />
		
		<!--- return the url str --->
		<cfreturn urlStr />
	</cffunction>
	
	<!---
	<cffunction name="getContent" access="remote" returntype="any" output="false">
		<cfargument name="id" type="string" required="true" />
		<cfargument name="siteId" type="string" required="true" />
	
		<cfset var local = structNew() />
	
		<!--- get content --->
		<cfquery datasource="#variables.dsn#" name="local.content"  username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			select 
				*
			from 
				tcontent 
				left join tfiles on (tcontent.fileid=tfiles.fileid)
			where 
				tcontent.contentId=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.id#" />
				and tcontent.siteId=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteId#" />
				and tcontent.active = 1
		</cfquery>
	
		<cfreturn local />
	</cffunction>
	--->
	
	<!---
	<cffunction name="listPublishableContent" access="remote" returntype="any" output="false">
		
		<cfset var local = structNew() />
		
		<!--- get publishable content --->
		<cfquery datasource="#variables.dsn#" name="local.content"  username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			select 
				qActivePublisherPage.activePublisherPage AS activePublisherPage,
				tcontent.contentId,
				tcontent.contentHistId,
				tcontent.siteId
			from 
				tcontent 
				left join tfiles on (tcontent.fileid=tfiles.fileid)
				
				<!--- active --->
				LEFT JOIN (
					SELECT 
						attributeValue AS activePublisherPage,
						baseId
					FROM 
						tclassextenddata
						INNER JOIN tclassextendattributes ON tclassextenddata.attributeID = tclassextendattributes.attributeID
					WHERE 
						tclassextendattributes.name = 'activePublisherPage'
				) qActivePublisherPage ON qActivePublisherPage.baseId = tcontent.contentHistId
				
			where 
				tcontent.active = 1
				AND activePublisherPage = 'Yes'
		</cfquery>

		<cfreturn local />
	</cffunction>
	--->

</cfcomponent>