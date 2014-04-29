<cfcomponent output="false" extends="Translator">

	<cffunction name="translate" access="public" returntype="void" output="false">
		<cfargument name="data" type="struct" required="true" />
		<cfargument name="bean" type="any" required="true" />
		
		<cfset var local = structNew() />

		<!--- ***************************************** --->
		<!--- ASSIGN CATEGORIES TO CONTENT --->
		<!--- ***************************************** --->
		<!--- assign the categories --->
		<cfloop query="data.categories">
			<!--- get local version of remote category --->
			<cfset local.localCategory = application.categoryManager.getBean().loadBy( remoteId:categoryId, siteId:bean.getSiteId() ) />
		
			<!--- assign the category to the bean --->
			<cfset arguments.bean.setCategory(
				categoryId: local.localCategory.getCategoryId(),
				featureStart: data.categories.featureStart,
				featureStop: data.categories.featureStop	
			) />	
		</cfloop>
		
		<!--- GLOBAL SCRUB --->
		<cfset super.translate( data:arguments.data.bean, bean:arguments.bean ) />
		
		<!--- push in the file if one was found within the data that came back from he publisher --->
		<cfif structKeyExists( arguments.data, "file" )>
			<!--- <cfset arguments.bean.setValue( "newFile", arguments.data.file ) /> --->
		</cfif>
				
		<!--- ***************************************** --->
		<!--- SCRUB CONTENT --->
		<!--- ***************************************** --->	
		<!--- IMPORTANT: it's important to really scrub the data before it's inserted into the bean
		otherwise extenedsetid's could be off --->
		<cfset structDelete( arguments.data.bean, "path" ) />
		<cfset structDelete( arguments.data.bean, "filename" ) />
		<cfset structDelete( arguments.data.bean, "fileId" ) />
		<cfset structDelete( arguments.data.bean, "contentId" ) />
		<cfset structDelete( arguments.data.bean, "contentHistId" ) />
		<cfset structDelete( arguments.data.bean, "isNew" ) />
		<cfset structDelete( arguments.data.bean, "lastupdatedby" ) />
		<cfset structDelete( arguments.data.bean, "lastupdatedbyid" ) />
		<cfset structDelete( arguments.data.bean, "extendsetid" ) />
		<cfset structDelete( arguments.data.bean, "parentId" ) />
		<cfset structDelete( arguments.data.bean, "remotePubDate" ) />
		<!--- clear out publisher settings if any exist --->
		<cfset structDelete( arguments.data.bean, "publisherOverrideChildrenToActive" ) />
		<cfset structDelete( arguments.data.bean, "activePublisherPage" ) />
		<cfset structDelete( arguments.data.bean, "preserveid" ) />
		<cfset structDelete( arguments.data.bean, "subscribeToAllChildPages" ) />
		<cfset structDelete( arguments.data.bean, "autoUpdateSubscriberPage" ) />
		<cfset structDelete( arguments.data.bean, "subscriberPublisherPageLastReleaseDate" ) />
		
		<!--- ***************************************** --->
		<!--- CONTENT BEAN --->
		<!--- ***************************************** --->	
		<!--- set the release date --->
		<cfset arguments.bean.setRemotePubDate( arguments.data.bean.lastUpdate ) />
						
		<!--- set the data into the bean --->
		<cfset arguments.bean.set( arguments.data.bean ) />
		
	</cffunction>
	
</cfcomponent>