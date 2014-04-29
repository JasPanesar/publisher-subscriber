<cfcomponent output="false" extends="Builder">

	<cfset variables.acceptedDisplayObjects = "Component,Form,Feed" />

	<cffunction name="build" access="public" returntype="void" output="false">
		<cfargument name="publisherProxyURL" type="string" required="true" hint="I am the publisher 'key' so you know which publisher has called you" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="remoteId" type="string" required="true" hint="Id of the content that needs to be updated (from publisher)"/>
		<cfargument name="remoteSiteId" type="string" required="true" hint="I am the site ID from the publisher" />
		<cfargument name="remoteParentId" type="string" required="true" hint="If the content id passed has a parent id, then the parent is passed for greater filtering" />			
		<cfargument name="localSiteId" type="string" required="true" hint="I am the site ID of the subscriber" />
		<cfargument name="contentBean" type="any" required="true" />
		<cfargument name="tempCache" type="struct" required="false" default="#structNew()#" />
	
		<cfset var local = structNew() />
	
		<!--- LOG --->
		<cfdump var="Gathering Regions" output="console" />
	
		<!--- ***************************************** --->
		<!--- ALL CATEGORIES --->
		<!--- ***************************************** --->
		<!--- fetch data from publisher --->
		<!--- loop over the available regions. currently there are 8 in mura --->
		<cfloop from="1" to="8" index="local.region">
			<!--- LOG --->
			<cfdump var="Gathering Region #local.region#" output="console" />
		
			<cfset local.contentDisplayRegionData = getSubscriberService().cacheFetch( 
				fetchMethod: "fetchContentDisplayRegionData",
				key: "#local.region##arguments.remoteId#",
				regionNum: local.region,
				publisherProxyURL: arguments.publisherProxyURL,
				subscriberId: arguments.subscriberId,
				id: arguments.remoteId,
				siteId: arguments.remoteSiteId,
				tempCache: arguments.tempCache
			) />
			
			<!--- LOG --->
			<cfdump var="Objects found: #local.contentDisplayRegionData.recordcount#" output="console" />
			
			<!--- loop over the records (objects) found --->
			<cfloop query="local.contentDisplayRegionData">
			
				<!--- if this is an accepted display object --->
				<cfif listFindNoCase( variables.acceptedDisplayObjects, object )>
					<!--- create the object --->
					<cfset local.displayObject = buildDisplayObject(
						displayObjectType: local.contentDisplayRegionData.Object,
						publisherProxyURL: arguments.publisherProxyURL,
						subscriberId: arguments.subscriberId,
						remoteId: objectId,
						remoteParentId: arguments.remoteParentId,
						remoteSiteId: arguments.remoteSiteId,
						localSiteId: arguments.localSiteId,
						tempCache: arguments.tempCache
					) />
							
					<!--- assign the display region object to the content node --->
					<!--- assignment will be different for a feed --->
					<cfif local.contentDisplayRegionData.Object IS "Feed">
						<!--- LOG --->
						<cfdump var="Object: #local.displayObject.getName()#" output="console" />
							
						<cfset arguments.contentBean.addDisplayObject(
							regionId: local.region,
							object: local.contentDisplayRegionData.Object,
							objectId: local.displayObject.getFeedId(),
							name: local.contentDisplayRegionData.Object & " - " & local.displayObject.getName()	
						) />
					<cfelse>
						<!--- LOG --->
						<cfdump var="Object: #local.displayObject.getMenuTitle()#" output="console" />
												
						<cfset arguments.contentBean.addDisplayObject(
							regionId: local.region,
							object: local.contentDisplayRegionData.Object,
							objectId: local.displayObject.getContentId(),
							name: local.displayObject.getType() & " - " & local.displayObject.getMenuTitle()	
						) />
					</cfif>
					
				</cfif>
			</cfloop>
			
		</cfloop>
	
	</cffunction>
	
	<cffunction name="buildDisplayObject" access="private" returntype="any" output="false">	
		<cfargument name="displayObjectType" type="string" required="true" />
		<cfargument name="publisherProxyURL" type="string" required="true" hint="I am the publisher 'key' so you know which publisher has called you" />
		<cfargument name="subscriberId" type="string" required="true" />
		<cfargument name="remoteId" type="string" required="true" hint="Id of the content that needs to be updated (from publisher)"/>
		<cfargument name="remoteParentId" type="string" required="true" hint="If the content id passed has a parent id, then the parent is passed for greater filtering" />						
		<cfargument name="remoteSiteId" type="string" required="true" hint="I am the site ID from the publisher" />
		<cfargument name="localSiteId" type="string" required="true" hint="I am the site ID of the subscriber" />
		<cfargument name="tempCache" type="struct" required="false" default="#structNew()#" />
	
		<cfset var local = structNew() />
			
		<!--- get publisher record --->
		<cfset local.publisher = getSubscriberService().readByPublisherProxyURL( arguments.publisherProxyURL ) />
		
		<!--- if we are a feed then we need to call the feed fetch --->
		<cfif arguments.displayObjectType IS "Feed">
			
			<!--- ************************************ --->
			<!--- BUILD FEED --->
			<!--- ************************************ --->
			<cfset getBuilderService().build(
				builderType: "feed",
				publisherProxyURL: arguments.publisherProxyURL,
				subscriberId: arguments.subscriberId,
				remoteId: arguments.remoteId,
				remoteParentId: arguments.remoteParentId,
				remoteSiteId: arguments.remoteSiteId,
				localSiteId: arguments.localSiteId,
				tempCache: arguments.tempCache	
			) />
			
			<!--- read it from the local database --->
			<!--- this is to check to see if we've already placed in the remove version --->
			<cfset local.displayObject = application.feedManager.getBean().loadBy( remoteId:"#arguments.remoteSiteId#|#arguments.remoteId#", siteId:arguments.localSiteId ) />
		
			<!--- get the feed object data --->
			<cfset local.contentData = getSubscriberService().cacheFetch(
				fetchMethod: "fetchFeedData",
				key: arguments.remoteId,
				bean: local.displayObject,
				publisherProxyURL: arguments.publisherProxyURL,
				subscriberId: arguments.subscriberId,
				id: arguments.remoteId,
				siteId: arguments.remoteSiteId,
				forceRequest: true,
				tempCache: arguments.tempCache		
			) />
			
		<cfelse>	
			
			<!--- read it from the local database --->
			<!--- this is to check to see if we've already placed in the remove version --->
			<cfset local.displayObject = application.contentManager.getBean().loadBy( remoteId:"#arguments.remoteSiteId#|#arguments.remoteId#", siteId:arguments.localSiteId ) />
			
			<!--- get the individual display object data --->
			<cfset local.contentData = getSubscriberService().cacheFetch( 
				fetchMethod: "fetchRemoteData", 
				key: arguments.remoteId,
				bean: local.displayObject,
				publisherProxyURL: arguments.publisherProxyURL,
				subscriberId: arguments.subscriberId,
				id: arguments.remoteId,
				siteId: arguments.remoteSiteId,
				forceRequest: true,
				tempCache: arguments.tempCache
			) />
			
		</cfif>
		
		<!--- check to see if the remote pub date and local pub dates are empty. if either of them are blank then save --->
		<!--- do a date diff from the remote remote pub date and the local remote pub date. if the remote remote pub date is newer then save --->				
		<cfif 
			NOT len( local.displayObject.getValue( "remotePubDate" ) )
			OR datediff( "s", local.contentData.bean.lastUpdate, local.displayObject.getValue( "remotePubDate" ) )>
			
			<!--- set the publisher id into the remote url field --->
			<cfset local.displayObject.setRemoteId( "#arguments.remoteSiteId#|#arguments.remoteId#" ) />
			<cfset local.displayObject.setRemoteSourceURL( local.publisher.get( 'id' ) ) />
			<!--- assign the site id into the category --->
			<cfset local.displayObject.setSiteId( arguments.localSiteId ) />
			
			<!--- translate the data into the bean --->
			<cfset getTranslatorService().translate( 
				translatorType: "region", 		
				data: local.contentData,
				bean: local.displayObject 
			) />
			
			<!--- LOG --->
			<cfdump var="Display object #local.displayObject.getMenuTitle()# saved" output="console" />	
			
			<!--- mirror the remote data --->
			<cfset local.displayObject.save() />
		</cfif>
		
		<!--- return the display object --->
		<cfreturn local.displayObject />
	</cffunction>
	
</cfcomponent>