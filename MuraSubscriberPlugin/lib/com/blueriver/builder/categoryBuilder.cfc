<cfcomponent output="false" extends="Builder">

	<cffunction name="build" access="public" returntype="void" output="false">
		<cfargument name="publisherProxyURL" type="string" required="true" hint="I am the publisher 'key' so you know which publisher has called you" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="remoteId" type="string" required="true" hint="Id of the content that needs to be updated (from publisher)"/>
		<cfargument name="remoteSiteId" type="string" required="true" hint="I am the site ID from the publisher" />
		<cfargument name="localSiteId" type="string" required="true" hint="I am the site ID of the subscriber" />
		<cfargument name="tempCache" type="struct" required="false" default="#structNew()#" />
	
		<cfset var local = structNew() />
	
		<!--- ***************************************** --->
		<!--- ALL CATEGORIES --->
		<!--- ***************************************** --->
		<!--- fetch data from publisher --->
		<cfset local.contentCategoryData = getSubscriberService().cacheFetch(
			fetchMethod: "fetchContentCategoryData",
			key: "categories#arguments.remoteId#",
			publisherProxyURL: arguments.publisherProxyURL,
			subscriberId: arguments.subscriberId,
			id: arguments.remoteId,
			siteId: arguments.remoteSiteId,
			tempCache: arguments.tempCache
		) />	
		
		<!--- ***************************************** --->
		<!--- INDIVIDUAL CATEGORIES --->
		<!--- ***************************************** --->
		<cfloop query="local.contentCategoryData">
			<cfset buildCategory(
				publisherProxyURL: arguments.publisherProxyURL,
				subscriberId: arguments.subscriberId,
				remoteId: categoryId,
				remoteSiteId: arguments.remoteSiteId,
				localSiteId: arguments.localSiteId,
				tempCache: arguments.tempCache
			) />
		</cfloop>	
	
	</cffunction>
	
	<cffunction name="buildCategory" access="private" returntype="any" output="false">	
		<cfargument name="publisherProxyURL" type="string" required="true" hint="I am the publisher 'key' so you know which publisher has called you" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="remoteId" type="string" required="true" hint="Id of the content that needs to be updated (from publisher)"/>
		<cfargument name="remoteSiteId" type="string" required="true" hint="I am the site ID from the publisher" />
		<cfargument name="localSiteId" type="string" required="true" hint="I am the site ID of the subscriber" />
		<cfargument name="tempCache" type="struct" required="false" default="#structNew()#" />
			
		<cfset var local = structNew() />
			
		<!--- get publisher record --->
		<cfset local.publisher = getSubscriberService().readByPublisherProxyURL( arguments.publisherProxyURL ) />
			
		<!--- read it from the local database --->
		<!--- this is to check to see if we've already placed in the remove version --->
		<cfset local.category = application.categoryManager.getBean().loadBy( remoteId:arguments.remoteId, siteId:arguments.localSiteId ) />
	
		<!--- LOG --->
		<cfdump var="Gathering Category..." output="console" />
		<cfdump var="Category: #local.category.getName()#" output="console" />
	
		<!--- get the individual category data --->
		<cfset local.categoryData = getSubscriberService().cacheFetch(
			fetchMethod: "fetchCategoryData",
			key: arguments.remoteId,
			publisherProxyURL: arguments.publisherProxyURL,
			subscriberId: arguments.subscriberId,
			categoryId: arguments.remoteId,
			siteId: arguments.remoteSiteId,
			tempCache: arguments.tempCache
		) />
		
		<!--- if there is a parent id then we need to get it's content --->
		<cfif len( local.categoryData.parentId )>
		
			<!--- LOG --->
			<cfdump var="Category has Parent..." output="console" />
		
			<!--- create the parent --->
			<cfset buildCategory(
				publisherProxyURL: arguments.publisherProxyURL,
				subscriberId: arguments.subscriberId,
				remoteId: local.categoryData.parentId,
				remoteSiteId: arguments.remoteSiteId,
				localSiteId: arguments.localSiteId,
				tempCache: arguments.tempCache
			) />
		
			<!--- get the parent that was created --->
			<!--- we need to do a new read because the underlying build method runs a loop (one to many) --->
			<cfset local.parentCategory = application.categoryManager.getBean().loadBy( remoteId:local.categoryData.parentId, siteId:arguments.localSiteId ) />
		</cfif>
		
		<!--- check to see if the remote pub date and local pub dates are empty. if either of them are blank then save --->
		<!--- do a date diff from the remote remote pub date and the local remote pub date. if the remote remote pub date is newer then save --->
		<cfif 
			NOT len( local.category.getRemotePubDate() )
			OR datediff( "s", local.categoryData.lastUpdate, local.category.getRemotePubDate() )>
			
			<!--- set the publisher id into the remote url field --->
			<cfset local.category.setRemoteId( arguments.remoteId ) />
			<cfset local.category.setRemoteSourceURL( local.publisher.get( 'id' ) ) />
			<!--- assign the site id into the category --->
			<cfset local.category.setSiteId( arguments.localSiteId ) />
			
			<!--- translate the data into the bean --->
			<cfset getTranslatorService().translate(
				translatorType: "category", 	
				data: local.categoryData,
				bean: local.category 
			) />
			
			<!--- if there is a parent then set the parentId --->
			<cfif structKeyExists( local, "parentCategory" )>
				<cfset local.category.setParentId( local.parentCategory.getCategoryId() ) />
			</cfif>
			
			<!--- LOG --->
			<cfdump var="Category #local.category.getName()# saved" output="console" />
			
			<!--- mirror the remote data --->
			<cfset local.category.save() />
			
		</cfif>
		
	</cffunction>
	
</cfcomponent>