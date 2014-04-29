<cfcomponent output="false">

	<cfset variables.instanceKey = createUUID() />
	<cfset variables.contentManager = application.contentManager />
	
	<cfset variables.configBean=application.configBean />
	<cfset variables.dsn=application.configBean.getDatasource() />

	<cfset variables.pluginConfig = application.pluginManager.getConfig( listLast(listLast(getDirectoryFromPath(getCurrentTemplatePath()),variables.configBean.getFileDelim()),"_") ) />
	<cfset variables.subscriberDAO = variables.pluginConfig.getApplication().getValue( property:"subscriberDAO", autowire:true ) />
	<cfset variables.subscriberService = variables.pluginConfig.getApplication().getValue( property:"subscriberService", autowire:true ) />

	<cffunction name="ping" access="remote" returntype="boolean" output="false">
		<cfreturn true />
	</cffunction>
	
	<cffunction name="getPublisherActiveContent" access="remote" returntype="any" output="false" >
		<cfargument name="publisherId" type="uuid" required="true" />
		<cfargument name="customFormat" type="string" required="false" default="plain" />
		
		<cfset var local = structNew() />
		<cfset local.publisher = variables.subscriberDAO.readById( arguments.publisherId ) />
		<cfset local.json = createObject( "component", "plugins.#variables.pluginConfig.getDirectory()#.lib.org.utils.json" ) />
		
		<!--- get active content --->
		<cfinvoke webservice="#trim(local.publisher.get( 'PublisherMuraProxyURL' ))#?wsdl"
			method="login"
			returnVariable="local.login">
			<cfinvokeargument name="username" value="#local.publisher.get( 'publisherUsername' )#">
			<cfinvokeargument name="password" value="#local.publisher.get( 'publisherPassword' )#">
			<cfinvokeargument name="siteID" value="#local.publisher.get( 'publisherUserAssignedSiteId ')#">
		</cfinvoke>
	
		<cfset local.args = structNew() />
		<cfset local.args.siteId = local.publisher.get( 'publisherUserAssignedSiteId' ) />
		<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL') )#?wsdl"
			method="call"
			returnVariable="local.webserviceResults">
			<cfinvokeargument name="serviceName" value="publisher">
			<cfinvokeargument name="methodName" value="getActiveContent">
			<cfinvokeargument name="authToken" value="#local.login#">
			<cfinvokeargument name="args" value="#local.args#" />
		</cfinvoke>
		
		<!--- format to json and release if asked to do so --->
		<cfif arguments.customFormat IS "json">
			<cfoutput>#local.json.encode( local.webserviceResults )#</cfoutput><cfabort>
		</cfif>
		
		<cfreturn local.webserviceResults />
	</cffunction>
	
	<cffunction name="localNewRequest" access="remote" returntype="any" output="false">
		<cfargument name="builderType" type="string" required="true" />
		<cfargument name="publisherId" type="string" required="true" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="remoteId" type="string" required="true" />
		<cfargument name="remoteParentId" type="string" required="true" />
		<cfargument name="remoteSiteId" type="string" required="true" />
		<cfargument name="topId" type="string" required="true" />
		
		<!---
		<cfset var local = structNew() />
		--->
		
		<!--- trigger this as a refresh --->
		<!--- this should only happen if the parent is requesting the refresh --->
		<!--- <cfset arguments.isParentRefresh = true /> --->
		<!--- we want to force the update since the admin requested it --->
		<!---
		<cfset arguments.forceRequest = true />
		
		<!--- get the publisher URL --->
		<cfset local.publisher = variables.subscriberDAO.readById( arguments.publisherId ) />
		<cfset arguments.publisherProxyURL = local.publisher.get( 'publisherProxyURL' ) />
		--->
		
		<!--- ask to make request --->
		<cfset variables.subscriberService.localNewRequest( argumentCollection:arguments ) />
		
		<!---
		<!--- route back to appropriate location --->
		<cflocation url="/admin/index.cfm?fuseaction=cArch.list&siteid=#arguments.subScriberSiteId#&topid=#arguments.topId#&moduleid=00000000000000000000000000000000000" addtoken="true" />
		--->
	</cffunction>
	
	<cffunction name="newRequest" access="remote" returntype="any" output="false">
		<cfargument name="builderType" type="string" required="true" hint="I would be one of the mura types (Content, etc)" />
		<cfargument name="publisherProxyURL" type="string" required="true" hint="I am the publisher 'key' so you know which publisher has called you" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="remoteId" type="string" required="true" hint="Id of the content that needs to be updated (from publisher)"/>
		<cfargument name="remoteParentId" type="string" required="true" hint="If the content id passed has a parent id, then the parent is passed for greater filtering" />
		<cfargument name="remoteSiteId" type="string" required="true" hint="I am the site ID from the publisher" />
		<!--- <cfargument name="isParentRefresh" type="boolean" required="false" default="false" /> --->
		<cfargument name="forceRequest" type="boolean" required="false" default="false" />
		
		<!---
		<cfdump var="Subscriber #arguments.subscriberId# proxy hit with id #arguments.id# and parent id #arguments.parentId#" output="console" />
		--->
		
		<!--- if this is not a valid plugin then continue --->
		<!---
		<cfdump var="#local.subscriberPlugin.getPackage()#" output="console" />
		<cfif local.subscriberPlugin.getPackage() IS NOT "MuraSubscriberPlugin">
			<cfdump var="ERROR: This is not a valid subscriber plugin" output="console" />
			<cfreturn "ERROR: This is not a valid subscriber plugin" />
		</cfif>
		--->
		
		<!---
		<cfdump var="#local.idCheck#" output="console" />
		<cfdump var="#arguments.isRefresh#" output="console" />
		--->				
		
		<!--- call the builder based on the type passed --->
		<cfset variables.subscriberService.newRequest( argumentCollection:arguments ) />
					
		<!--- if there is no content id then we need to create one --->
		<!---
		<cfthread name="run#createUUID()#" action="run" scope="#local#">
		--->	
	</cffunction>	
	
	<!---	
	<cffunction name="fetchRemoteData" access="private" returntype="any" output="false">
		<cfargument name="bean" type="any" required="true" />
		<cfargument name="publisherProxyURL" type="string" required="true" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="id" type="string" required="true" />
		<cfargument name="parentId" type="string" required="true" />
		<cfargument name="siteId" type="string" required="true" />
		<!--- <cfargument name="isParentRefresh" type="boolean" required="false" default="false" /> --->
		<cfargument name="forceRequest" type="boolean" required="false" default="false" />
	
		<cfset var local = structNew() />
		
		<!--- ammend arguments to local --->
		<cfset local.args = arguments />
		
		<!--- attempt to get the subscriber plugin --->
		<cfset local.subscriberPlugin = application.pluginManager.getConfig( arguments.subscriberId ) />
	
		<!--- get lib package --->
		<cfset local.libPackage = local.subscriberPlugin.getApplication().getValue( "libPackage" ) />
		
		<!--- get publisher record --->
		<cfset local.publisher = local.libPackage.subscriberDAO.readByPublisherProxyURL( arguments.publisherProxyURL ) />
		
		<!--- throw an error if the publisher is disabled or does not exist --->
		<cfif local.publisher.get( "isNew" ) OR NOT local.publisher.get( "enabled" )>
			<cfreturn "ERROR: Publisher disabled or does not exist" />
		</cfif>
	
		<!--- create a deep copy of the current content data --->
		<cfset local.deepCopyOfLocalData = duplicate( arguments.bean.getAllValues() ) />
	
		<!--- only attempt to update the page if set to auto-update or the update is forced --->
		<cfif arguments.bean.getValue( "autoUpdateSubscriberPage" ) IS "Yes" OR arguments.forceRequest OR arguments.bean.get( "IsNew" ) IS "Yes">
			<cftry>
	
				<!--- get content from publisher --->
				<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL' ))#?wsdl"
					method="login"
					returnVariable="local.login">
					<cfinvokeargument name="username" value="#local.publisher.get( 'publisherUsername' )#">
					<cfinvokeargument name="password" value="#local.publisher.get( 'publisherPassword' )#">
					<cfinvokeargument name="siteID" value="#local.publisher.get( 'publisherUserAssignedSiteId' )#">
				</cfinvoke>
				
				<!--- get data from mura proxy --->
				<cfset local.webserviceArgs = structNew() />
				<cfset local.webserviceArgs.siteId = local.args.siteId />
				<cfset local.webserviceArgs.contentId = local.args.id />
				<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL' ))#?wsdl"
					method="call"
					returnVariable="local.webserviceResults">
					<cfinvokeargument name="serviceName" value="publisher">
					<cfinvokeargument name="methodName" value="read">
					<cfinvokeargument name="authToken" value="#local.login#">
					<cfinvokeargument name="args" value="#local.webserviceArgs#">
				</cfinvoke>
				
				<!---
				<cfdump var="#local.contentBean.getValue( 'contentId' )#" output="console" />
				--->
				
				<!--- ***************************************** --->
				<!--- SCRUB CONTENT --->
				<!--- ***************************************** --->	
				<!--- IMPORTANT: it's important to really scrub the data before it's inserted into the bean
				otherwise extenedsetid's could be off --->
				<!---
				<cfset structDelete( local.webserviceResults, "path" ) />
				<cfset structDelete( local.webserviceResults, "filename" ) />
				<cfset structDelete( local.webserviceResults, "contentId" ) />
				<cfset structDelete( local.webserviceResults, "contentHistId" ) />
				<cfset structDelete( local.webserviceResults, "isNew" ) />
				<cfset structDelete( local.webserviceResults, "lastupdatedby" ) />
				<cfset structDelete( local.webserviceResults, "lastupdatedbyid" ) />
				<cfset structDelete( local.webserviceResults, "extendsetid" ) />
				<cfset structDelete( local.webserviceResults, "siteId" ) />
				<cfset structDelete( local.webserviceResults, "parentId" ) />
				<cfset structDelete( local.webserviceResults, "remoteId" ) />
				<cfset structDelete( local.webserviceResults, "remoteURL" ) />
				<cfset structDelete( local.webserviceResults, "remotePubDate" ) />
				<!--- clear out publisher settings if any exist --->
				<cfset structDelete( local.webserviceResults, "publisherOverrideChildrenToActive" ) />
				<cfset structDelete( local.webserviceResults, "activePublisherPage" ) />
				<cfset structDelete( local.webserviceResults, "preserveid" ) />
				<cfset structDelete( local.webserviceResults, "subscribeToAllChildPages" ) />
				<cfset structDelete( local.webserviceResults, "autoUpdateSubscriberPage" ) />
				<cfset structDelete( local.webserviceResults, "subscriberPublisherPageLastReleaseDate" ) />
				--->
				
				<!--- build out the content bean (translate remote content to local bean) --->
				<cfset local.libPackage.builderService.build( local.webserviceResults, arguments.bean ) />
				<!--- set remote hooks --->				
				<cfset arguments.bean.setRemoteId( local.args.siteId & "|" & local.args.id ) />
				<cfset arguments.bean.setRemoteURL( trim(local.publisher.get( 'id' )) ) />
				
				
				<!--- ***************************************** --->
				<!--- PRESERVATION --->
				<!--- ***************************************** --->	
				<!--- keep all extended data associated to subscriber --->
				<!---
				<cfif structKeyExists( local.deepCopyOfCurrentData, "subscribeToAllChildPages" )>
					<cfset local.contentBean.setValue( "subscribeToAllChildPages", local.deepCopyOfCurrentData.subscribeToAllChildPages ) />
				</cfif>
				<cfif structKeyExists( local.deepCopyOfCurrentData, "autoUpdateSubscriberPage" )>
					<cfset local.contentBean.setValue( "autoUpdateSubscriberPage", local.deepCopyOfCurrentData.autoUpdateSubscriberPage ) />
				</cfif>
				--->
				<!--- the below should only be set if a record has been found --->
				<!---
				<cfif local.idCheck.recordcount>
					<cfset local.contentBean.setContentId( local.idCheck.contentId ) />
					<cfset local.contentBean.setContentHistId( local.idCheck.contentHistId ) />
				</cfif>
				--->
				
				<!--- set the data into the bean --->
				<!---
				<cfset arguments.contentBean.set( local.webserviceResults ) />				
				--->
										
				<!--- hard set a variable to ensure the below save does not retrigger this save content event --->
				<cfset arguments.bean.setValue( "preventEventRefire", true  ) />
					
				<!--- save the content --->
				<cfset application.bean.save( arguments.bean ) />
				
				<!--- only get kids if asked to do so --->
				<cfif ( structKeyExists( local.deepCopyOfLocalData, "subscribeToAllChildPages" ) AND local.deepCopyOfLocalData.subscribeToAllChildPages IS "Yes" ) OR arguments.bean.get( "IsNew" ) IS "Yes">
					<!--- ************************************ --->
					<!--- GET KIDS --->
					<!--- ************************************ --->
					<cfinvoke webservice="#trim(local.publisher.get( 'publisherMuraProxyURL' ))#?wsdl"
						method="call"
						returnVariable="local.webserviceKidsResults">
						<cfinvokeargument name="serviceName" value="publisher">
						<cfinvokeargument name="methodName" value="getKids">
						<cfinvokeargument name="authToken" value="#local.login#">
						<cfinvokeargument name="args" value="#local.webserviceArgs#">
					</cfinvoke>
				
					<!--- loop over the kids --->
					<cfloop query="local.webserviceKidsResults">
						<cfset newRequest( 
							publisherProxyURL:arguments.publisherProxyURL,
							subscriberId: arguments.subscriberId,
							id: local.webserviceKidsResults.contentId,
							parentId: local.args.id,
							siteId: arguments.siteId,
							forceRequest: false
						) />
					</cfloop>
				</cfif>
						
				<!--- update the bean --->
				<!---
				<cfdump var="#local.contentBean.getValue( 'contentId' )#" output="console" />
					
				<cfdump var="successful hit" output="console" />
				--->
				
				<cfcatch>
					
					<!--- capture error --->
					<cfsavecontent variable="local.errorDump">Subscriber: <cfoutput>#local.publisher.get( 'publisherPluginProxyURL' )#</cfoutput><br /><cfdump var="#cfcatch#" /></cfsavecontent>
					<!--- ammend to log --->
					<cffile action="write" file="#getDirectoryFromPath( getCurrentTemplatePath() )#/log/error_#getTickCount()#.html" output="#local.errorDump#" />
					
				</cfcatch>
			</cftry>
		</cfif>	
			
		<!---
		</cfthread>
		--->
	
		<!--- return true --->
		<!--- <cfreturn local /> --->
		
	</cffunction>
	--->

</cfcomponent>