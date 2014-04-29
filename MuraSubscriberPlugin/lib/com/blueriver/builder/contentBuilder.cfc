<cfcomponent output="false" extends="Builder">

	<cffunction name="build" access="public" returntype="void" output="false">
		<cfargument name="builderType" type="string" required="true" hint="I would be one of the mura types (Content, etc)" />
		<cfargument name="publisherProxyURL" type="string" required="true" hint="I am the publisher 'key' so you know which publisher has called you" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="remoteId" type="string" required="true" hint="Id of the content that needs to be updated (from publisher)"/>
		<cfargument name="remoteParentId" type="string" required="true" hint="If the content id passed has a parent id, then the parent is passed for greater filtering" />
		<cfargument name="remoteSiteId" type="string" required="true" hint="I am the site ID from the publisher" />
		<cfargument name="localSiteId" type="string" required="false" default="" hint="I am the site ID of the subscriber" />
		<cfargument name="forceRequest" type="boolean" required="false" default="false" />		
		<cfargument name="tempCache" type="struct" required="false" default="#structNew()#" />
		<cfargument name="childParentId" type="string" required="false" />
	
		<cfset var local = structNew() />
	
		<!--- get publisher information --->
		<cfset local.publisher = getSubscriberService().readByPublisherProxyURL( arguments.publisherProxyURL ) />
	
		<!--- check to see if the parent exists --->
		<cfquery datasource="#variables.dsn#" name="local.parentCheck"  username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			select 
				tcontent.contentId,
				tcontent.contentHistId,
				tcontent.parentId,
				tcontent.siteId
			from 
				tcontent 
				left join tfiles on (tcontent.fileid=tfiles.fileid)
			where 
				<cfif isDefined( "arguments.childParentId" )>
					tcontent.contentId = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.childParentId#" />
				<cfelse>
					tcontent.remoteId = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.remoteSiteId#|#arguments.remoteParentId#" />		
				</cfif>
				and tcontent.active = 1
		</cfquery>
		
		<!--- query database and look for remote id --->
		<!--- TODO: we should maybe look into adjusting the content manager query a little os it does not need a siteid --->
		<!--- TODO: need to look into making this more dynamic so it can look against different types --->
		<cfquery datasource="#variables.dsn#" name="local.idCheck"  username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			select 
				tcontent.*, 
				tfiles.fileSize, 
				tfiles.contentType, 
				tfiles.contentSubType, 
				tfiles.fileExt,
				qSubscribeToAllChildPages.subscribeToAllChildPages AS subscribeToAllChildPages
			from 
				tcontent 
				left join tfiles on (tcontent.fileid=tfiles.fileid)
				LEFT JOIN (
					SELECT 
						tclassextenddata.attributeId AS subscribeToAllChildPages,
						baseId
					FROM 
						tclassextenddata
						INNER JOIN tcontent ON tcontent.contentHistID = tclassextenddata.baseId
						INNER JOIN tclassextendattributes ON tclassextenddata.attributeID = tclassextendattributes.attributeID
					WHERE 
						tclassextendattributes.name = 'subscribeToAllChildPages'
						AND tclassextendattributes.siteID = tcontent.siteID
				) qSubscribeToAllChildPages ON qSubscribeToAllChildPages.baseId = tcontent.contentHistId
			where 
				tcontent.remoteID=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.remoteSiteId#|#arguments.remoteId#" />
				<!--- we do not include the parent search if the parent is making the request --->
				<!---
				<cfif local.parentCheck.recordcount AND arguments.parentId IS NOT arguments.id>
					and tcontent.parentId=<cfqueryparam cfsqltype="cf_sql_varchar" value="#local.parentCheck.contentId#" />
				</cfif>
				--->
				<cfif isDefined( "arguments.childParentId" )>
					and tcontent.parentId=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.childParentId#" />
				</cfif>
				and type in ('Page','Folder','File','Calendar','Link','Gallery','Component','Form')
				and tcontent.active = 1
		</cfquery>
		
		<!--- if there is no parent then stop --->
		<cfif NOT local.parentCheck.recordCount AND NOT local.idCheck.recordCount>
			<cfreturn "ERROR: Node not found" />
		</cfif>

		<!--- LOG --->
		<cfdump var="Gathering Content Bean (ID: #arguments.remoteId#)" output="console" />
		<!--- ***************************************** --->
		<!--- CONTENT BEAN --->
		<!--- ***************************************** --->
		<!--- load the bean if one is found based on the remoteId and content Id --->
		<!--- otherwise create a new bean --->
		<!--- this means a child bean has been found --->
		<cfset local.forceGetChildren = "No" />
		
		<cfset local.run = true />
		<cfset local.currentRecord = 0 />
		<!--- loop over record found and make associated calls. we could house this in memory, but it's not scalable --->
		<cfloop condition="local.run">
		
			<!--- inc current row --->
			<cfset local.currentRecord = local.currentRecord + 1 />

			<!--- get a fresh bean --->
			<cfset local.bean = application.contentManager.getBean() />
		
			<!--- only run if there is a recordcount --->
			<cfif local.idCheck.recordCount>
			
				<!--- get the bean --->
				<cfset local.bean.loadBy (
					contentId: local.idCheck.contentId[ local.currentRecord ], 
					parentId: local.idCheck.parentId[ local.currentRecord ],
					siteId: local.idCheck.siteId[ local.currentRecord ]	
				) />
					
				<!--- LOG --->
				<cfdump var="Bean found!" output="console" />	
				
				<cfdump var="Bean: #local.bean.getMenuTitle()#" output="console" />

				<!--- load up some content --->
				<cfset local.bean.setSiteId( local.IdCheck.siteId[ local.currentRecord ] ) />
				<!--- setup original values --->
				<cfset local.bean.setParentId( local.idCheck.parentId[ local.currentRecord ] ) /> 
	
			<cfelse>
			
				<!--- LOG --->
				<cfdump var="Bean not found..." output="console" />
				
				<!--- if the idCheck record(s) could not be found then we assume that the record is new and use the parentcheck content id as the parentid --->
				<!--- otherwise it's a child and we can just use the content id from the parent search --->
				<cfset local.bean.setSiteId( local.parentCheck.siteId ) />
				<cfset local.bean.setParentId( local.parentCheck.contentId ) />
				
				<!--- we tell all new pages to attempt to get children if available --->
				<cfset local.bean.setValue( "subscribeToAllChildPages", "Yes" ) />
				<!--- Auto update this page whenever the publisher page is updated --->
				<cfset local.bean.setValue( "autoUpdateSubscriberPage", "Yes" ) />
			</cfif>
			
			<!--- create a deep copy of the current content data --->
			<cfset local.deepCopyOfLocalData = duplicate( local.bean.getAllValues() ) />
			
			<!--- fetch data from publisher --->
			<!--- REMOTE CALL --->
			<cfset local.requestData = getSubscriberService().cacheFetch(
				fetchMethod: "fetchRemoteData",
				key: "bean#arguments.remoteId#",
				bean: local.bean,
				publisherProxyURL: arguments.publisherProxyURL,
				id: arguments.remoteId,
				subscriberId: arguments.subscriberId,
				forceRequest: arguments.forceRequest,
				tempCache: arguments.tempCache
			) />

			<!--- only run if it has been assigned to be published --->
			<cfif ( isSimpleValue( local.requestData ) AND local.requestData IS NOT "access denied" ) OR isStruct( local.requestData )>
			
				<!--- LOG --->
				<cfdump var="Gathering Associated Categories" output="console" />
				
				<!--- ***************************************** --->
				<!--- CATEGORIES --->
				<!--- ***************************************** --->
				<cfset getBuilderService().build(
					builderType: "category",
					publisherProxyURL: arguments.publisherProxyURL,
					subscriberId: arguments.subscriberId,
					remoteId: arguments.remoteId,
					remoteParentId: arguments.remoteParentId,
					remoteSiteId: arguments.remoteSiteId,
					localSiteId: local.parentCheck.siteId,
					tempCache: arguments.tempCache
				) />	
			
				<!--- hard set a variable to ensure the below save does not retrigger this save content event --->
				<cfset local.bean.setValue( "preventEventRefire", true  ) />
				
				<!--- only update the bean if it has changed (checked by lastupdate) --->
				<cfif 
					NOT len( local.bean.getValue( "remotePubDate" ) )
					OR ( structKeyExists( local.requestData.bean, "lastUpdate" ) AND dateDiff( 's', local.requestData.bean.lastUpdate, parseDateTime( local.bean.getValue( "remotePubDate" ))))>
				
					<!--- set the publisher id into the remote url field --->
					<cfset local.bean.setRemoteId( "#local.requestData.bean.siteId#|#local.requestData.bean.contentId#" ) />
					<cfset local.bean.setRemoteSourceURL( local.publisher.get( 'id' ) ) />
					
					<!---
					<cfset local.bean.setRemotePubDate( now() ) />
					--->
					<!--- fetch the data --->
					<cfset getTranslatorService().translate( 	
						translatorType: "content", 
						data: local.requestData,
						bean: local.bean 
					) />
					
					<!--- LOG --->
					<cfdump var="Gathering Display Objects" output="console" />
					
					<!--- ***************************************** --->
					<!--- FILES --->
					<!--- ***************************************** --->
					<cfif structKeyExists( local.requestData, "file" )>
						<!--- convert file information into a binary format --->
						<cfset local.objBinary = ToBinary( local.requestData.file ) />
						
						<!--- start creating file metadata for later use --->
						<cfset local.fileData = structNew() />
						<cfset local.fileData.clientFile = createUUID() />
						<cfset local.fileData.serverFileExt = local.requestData.fileMetaData.fileExt />
						<cfset local.fileData.serverfilename = left( local.requestData.fileMetaData.filename, len(local.requestData.fileMetaData.filename) - len(local.requestData.fileMetaData.fileExt) - 1) />
						<cfset local.fileData.serverDirectory = getTempDirectory() />
						<cfset local.fileData.serverFile = local.requestData.fileMetaData.filename />
						<cfset local.fileData.contentType = local.requestData.fileMetaData.contentType />
						<cfset local.fileData.contentSubType = local.requestData.fileMetaData.contentSubType />
						<cfset local.fileData.fileSize = local.requestData.fileMetaData.fileSize />
										
						<!--- place the file into the temp folder --->
						<cffile action="write" file="#local.fileData.serverDirectory##local.fileData.serverfilename#.#local.fileData.serverFileExt#" output="#local.objBinary#" />
						
						<!--- create file(s) --->
						<cfset local.theFileStruct = application.ServiceFactory.getBean( "fileManager" ).process( local.fileData, local.parentCheck.siteId ) />
						<!--- record files to Mura --->
						<cfset local.fileId = application.ServiceFactory.getBean( "fileManager" ).create(
							local.theFileStruct.fileObj,
							local.bean.getcontentID(),
							local.bean.getSiteID(),
							local.fileData.serverFile,
							local.fileData.ContentType,
							local.fileData.ContentSubType,
							local.fileData.FileSize,
							local.bean.getModuleID(),
							local.fileData.serverFileExt,
							local.theFileStruct.fileObjSmall,
							local.theFileStruct.fileObjMedium
						) />
						
						<!--- assign it to the local bean --->
						<cfset local.bean.setValue( "fileId", local.fileId ) />
					</cfif>
					
					<!--- ***************************************** --->
					<!--- DISPLAY OBJECTS --->
					<!--- ***************************************** --->
					<cfset getBuilderService().build(
						builderType: "region",
						publisherProxyURL: arguments.publisherProxyURL,
						subscriberId: arguments.subscriberId,
						remoteId: arguments.remoteId,
						remoteParentId: arguments.remoteParentId,
						remoteSiteId: arguments.remoteSiteId,
						localSiteId: local.parentCheck.siteId,
						contentBean: local.bean,
						tempCache: arguments.tempCache
					) />
					
					<!--- LOG --->
					<cfdump var="Gathering Related Content" output="console" />
					<!--- ***************************************** --->
					<!--- RELATED CONTENT --->
					<!--- ***************************************** --->
					<cfset getBuilderService().build(
						builderType: "relatedContent",
						publisherProxyURL: arguments.publisherProxyURL,
						subscriberId: arguments.subscriberId,
						remoteId: arguments.remoteId,
						remoteParentId: arguments.remoteParentId,
						remoteSiteId: arguments.remoteSiteId,
						localSiteId: local.parentCheck.siteId,
						contentBean: local.bean,
						tempCache: arguments.tempCache
					) />
					
					<!--- LOG --->
					<cfdump var="Content bean #local.bean.getMenuTitle()# saved" output="console" />
				
					<!--- save the bean --->
					<cfset local.bean.save() />
					
				</cfif>
			
				<!--- ******************************************** --->
				<!--- only get kids if asked to do so --->
				<!--- ******************************************** --->
				<cfif ( 
						structKeyExists( local.deepCopyOfLocalData, "subscribeToAllChildPages" ) 
						AND local.deepCopyOfLocalData.subscribeToAllChildPages IS "Yes" 
					) 
					OR local.bean.getValue( "IsNew" ) IS "Yes">
					<!--- ************************************ --->
					<!--- GET KIDS --->
					<!--- ************************************ --->
					<cfset local.webserviceKidsResults = getSubscriberService().cacheFetch(
						fetchMethod: "fetchRemoteKidsData",
						key: "kids#arguments.remoteId#",
						publisherProxyURL: publisherProxyURL,
						subscriberId: arguments.subscriberId,
						id: arguments.remoteId,
						siteId: arguments.remoteSiteId,
						tempCache: arguments.tempCache
					) />
					
					<!--- only run if a query comes back --->
					<cfif isQuery( local.webserviceKidsResults )>
						<!--- LOG --->
						<cfdump var="Kids Found: #local.webserviceKidsResults.recordCount#" output="console" />
						
						<!--- loop over the kids --->
						<!--- since we do a recursive request we hit the build method again --->
						<cfloop query="local.webserviceKidsResults">
							<!--- LOG --->
							<cfdump var="Gathering Kid... #local.webserviceKidsResults.menuTitle#" output="console" />
							<cfset build( 
								builderType: arguments.builderType,
								publisherProxyURL:arguments.publisherProxyURL,
								subscriberId: arguments.subscriberId,
								remoteId: local.webserviceKidsResults.contentId,
								remoteParentId: arguments.remoteId,
								remoteSiteId: arguments.remoteSiteId,
								localSiteId: arguments.localSiteId,
								forceRequest: false,
								tempCache: arguments.tempCache,
								childParentId: local.bean.getContentId()
							) />
						</cfloop>
						
					</cfif>
				</cfif>
			
			</cfif>
			
			<!--- stop the loop if the recordcount is 0 ir idcheck recordcount has been hit --->
			<cfif NOT local.idCheck.recordCount OR local.currentRecord IS local.idCheck.recordCount>
				<cfset local.run = false />
			</cfif>	
		
		</cfloop>
	
	</cffunction>
	
</cfcomponent>