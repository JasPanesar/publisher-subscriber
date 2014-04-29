<cfcomponent output="false" extends="mura.proxy.content">

	<cffunction name="read" output="false">
		<cfargument name="event">
		<cfset var results = structNew() />
		<cfset var content=getBean(event)>
		<cfset var perm=getPerm(event)>
		
		<!--- publisher security wrapper --->
		<cfif isActive(content) OR listFindNoCase( "Component,Form,File", content.getType() )>
			<cfif perm.level neq "deny">
				<cfset results.bean=content.getAllValues()>
				<cfset results.categories=content.getCategoriesQuery()>
				<cfset results.relatedContent=content.getRelatedContentQuery()>
				
				<cfif len( content.getFileId() )>
					<!---
					<cfset local.fileMeta = application.serviceFactory.getBean('fileManager').readMeta( content.getFileId() ) />
					<cfset local.delim = application.configBean.getFileDelim() />
					<cfset local.theFileLocation="#application.configBean.getFileDir()##local.delim##local.fileMeta.siteid##local.delim#cache#local.delim#file#local.delim##content.getFileID()#.#local.fileMeta.fileExt#" />
					<cffile action="read" file="#local.theFileLocation#" variable="local.theFile">
					<cfset results.file = local.theFile />
					<cfdump var="#results#" output="console" />
					--->
					<!---
					<cfset results.file = ToBase64( application.serviceFactory.getBean('fileManager').renderFile( content.getValue( "fileId" ) ) ) />
					--->
					<cfset local.fileMeta = application.serviceFactory.getBean('fileManager').readMeta( content.getFileId() ) />
					<cfset local.delim = application.configBean.getFileDelim() />
					<cfset local.theFileLocation="#application.configBean.getFileDir()##local.delim##local.fileMeta.siteid##local.delim#cache#local.delim#file#local.delim##content.getFileID()#.#local.fileMeta.fileExt#" />
					<cffile action="readBinary" file="#local.theFileLocation#" variable="local.theFile">
					
					<!--- save file content --->
					<cfset results.file = ToBase64( local.theFile ) />
					
					<!--- get file metadata --->
					<cfset results.fileMetaData = application.serviceFactory.getBean('fileManager').readMeta( content.getFileId() ) />
					
				</cfif>
			
				<cfset event.setValue("__response__", format(results,event.getValue("responseFormat")))>
			<cfelse>
				<cfset event.setValue("__response__", format("access denied",event.getValue("responseFormat")))>
			</cfif>
		<cfelse>
			<!--- <cfthrow message="The content requested is not available" /> --->
			<cfset event.setValue("__response__", format("access denied",event.getValue("responseFormat")))>
		</cfif>
		
	</cffunction>

	<cffunction name="getKids" output="false">
		<cfargument name="event">
		<cfset var content=getBean(event)>
		<cfset var perm=getPerm(event)>
		
		<!--- publsher security wrapper --->
		<cfif isActive(content)>
			<cfif perm.level neq 'Deny'>
				<cfset event.setValue("__response__", format(application.contentManager.getKidsQuery(siteID=content.getSiteID(), parentID=content.getContentID(), sortBy=content.getSortBy(), sortDirection=content.getSortDirection(), aggregation=false, size=1000), event.getValue("responseFormat")))>
			<cfelse>
				<cfset event.setValue("__response__", format("access denied", event.getValue("responseFormat")))>
			</cfif>
		<cfelse>
			<!--- <cfthrow message="The content requested is not available" /> --->
			<cfset event.setValue("__response__", format("access denied",event.getValue("responseFormat")))>
		</cfif>
		
	</cffunction> 
	
	<cffunction name="getLastUpdate" output="false">
		<cfargument name="event" />
		
		<cfset var local = structNew() />
		
		<!--- get the content bean based on the id and contentid passed --->
		<cfset local.contentBean = application.contentManager.getActiveContent( event.getValue( "contentId" ), event.getValue( "siteId" ) ) />
	
		<cfset event.setValue( "__response__", format( local.contentBean.getLastUpdate(), event.getValue("responseFormat") ) ) />
	</cffunction>

	<cffunction name="getActiveContent" output="false">
		<cfargument name="event" />
		
		<cfset var local = structNew() />
		
		<cfset local.feed = event.getBean( "feed" ) />
		<cfset local.feed.setType('custom') />
		<cfset local.feed.setSiteID(event.getValue( "siteid" ) ) />
		<cfset local.feed.addAdvancedParam(relationship='AND', field='activePublisherPage', criteria="Yes", condition='EQ', dataType='varchar')>
		<cfset local.feed.setShowNavOnly(0)>
		<cfset local.feed.setShowExcludeSearch(1)>
		
		<cfset event.setValue("__response__", format(local.feed.getQuery(),event.getValue("responseFormat")))>
	</cffunction>

	<cffunction name="getCategories" output="false">
		<cfargument name="event" />
		<cfset var content=getBean(event)>
		<cfset var perm=getPerm(event)>
		
		<!--- publisher security wrapper --->
		<cfif isActive(content) OR listFindNoCase( "Component,Form,File", content.getType() )>
			<cfif perm.level neq "deny">
				<cfset content=content.getCategoriesQuery()>
		
				<cfset event.setValue("__response__", format(content,event.getValue("responseFormat")))>
			<cfelse>
				<cfset event.setValue("__response__", format("access denied",event.getValue("responseFormat")))>
			</cfif>
		<cfelse>
			<!--- <cfthrow message="The content requested is not available" /> --->
			<cfset event.setValue("__response__", format("access denied",event.getValue("responseFormat")))>
		</cfif>
	</cffunction>
	<cffunction name="getCategory" output="false">
		<cfargument name="event" />
		<cfset var content=application.categoryManager.read(categoryId:event.getValue( "categoryId" ), siteId:event.getValue( "siteId" ) ) />
		
		<cfset content=content.getAllValues()>
		<cfset event.setValue("__response__", format(content,event.getValue("responseFormat")))>

	</cffunction>

	<cffunction name="getDisplayRegion" output="false">
		<cfargument name="event" />
		<cfset var content=getBean(event)>
		<cfset var perm=getPerm(event)>
		
		<!--- publsher security wrapper --->
		<!--- <cfif isActive(content)> --->
			<cfif perm.level neq 'Deny'>
				<cfset event.setValue("__response__", format(content.getDisplayRegion(event.getValue("regionNum")),event.getValue("responseFormat")))>
			<cfelse>
				<cfset event.setValue("__response__", format("access denied",event.getValue("responseFormat")))>
			</cfif>
		<!---
		<cfelse>
			<cfthrow message="The content requested is not available" />
		</cfif>
		--->

	</cffunction>

	<cffunction name="getFeed" output="false">
		<cfargument name="event" />
		<cfset var feed=application.feedManager.read(feedId:event.getValue( "feedId" ), siteId:event.getValue( "siteId" ) ) />
		
		<cfset var local = structNew() />
		
		<cfset feed=feed.getAllValues()>
		<cfset local.bean = feed />
		
		<cfset event.setValue("__response__", format(local,event.getValue("responseFormat")))>

	</cffunction>
	
	<!---
	<cffunction name="getFile" output="false">
		<cfargument name="event">
		<cfset var results = structNew() />
		<cfset var content=getBean(event)>
			
		<cfif len( content.getFileId() )>
			<cfdump var="#application.serviceFactory.getBean('fileManager').renderFile( content.getFileId() )#" output="console" />
			<cfset results.file = application.serviceFactory.getBean('fileManager').renderFile( content.getFileId() ) />
			<cfset event.setValue("__response__", format(results.file,event.getValue("responseFormat")))>
		</cfif>
	</cffunction>
	--->
	
	<cffunction name="isActive" access="private" returntype="boolean" output="false">
		<cfargument name="content" type="any" required="true" />
		<!--- check to see if the node is active via the publisher --->
		<cfif (
			arguments.content.getParent().getValue( "publisherOverrideChildrenToActive" ) IS "Yes" 
			OR 
			arguments.content.getValue( "activePublisherPage" ) IS "Yes"	
			)>
			<cfreturn true />
		</cfif>
		<cfreturn false />
	</cffunction> 

</cfcomponent>