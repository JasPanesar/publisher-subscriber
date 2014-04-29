<cfcomponent output="false" extends="Builder">

	<cffunction name="build" access="public" returntype="void" output="false">
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
		<cfset local.feed = application.feedManager.getBean().loadBy( remoteId:"#arguments.remoteSiteId#|#arguments.remoteId#", siteId:arguments.localSiteId ) />
	
		<!--- LOG --->
		<cfdump var="Gathering Feed..." output="console" />
		<cfdump var="Feed: #local.feed.getName()#" output="console" />
	
		<!--- get the individual feed data --->
		<cfset local.feedData = getSubscriberService().cacheFetch(
			fetchMethod: "fetchFeedData",
			key: arguments.remoteId,
			id: arguments.remoteId,
			publisherProxyURL: arguments.publisherProxyURL,
			subscriberId: arguments.subscriberId,
			categoryId: arguments.remoteId,
			siteId: arguments.remoteSiteId,
			tempCache: arguments.tempCache
		) />
		
		<!--- check to see if the remote pub date and local pub dates are empty. if either of them are blank then save --->
		<!--- do a date diff from the remote remote pub date and the local remote pub date. if the remote remote pub date is newer then save --->				
		<cfif 
			NOT len( local.feed.getValue( "remotePubDate" ) )
			OR datediff( "s", local.feedData.bean.lastUpdate, local.feed.getValue( "remotePubDate" ) )>
			
			<!--- set the publisher id into the remote url field --->
			<cfset local.feed.setRemoteId( "#arguments.remoteSiteId#|#arguments.remoteId#" ) />
			<cfset local.feed.setRemoteSourceURL( local.publisher.get( 'id' ) ) />
			<!--- assign the site id into the category --->
			<cfset local.feed.setSiteId( arguments.localSiteId ) />
			
			<!--- translate the data into the bean --->
			<cfset getTranslatorService().translate(
				translatorType: "feed", 	
				data: local.feedData,
				bean: local.feed 
			) />
			
			<!--- LOG --->
			<cfdump var="Feed #local.feed.getName()# saved" output="console" />
			
			<!--- mirror the remote data --->
			<cfset local.feed.save() />
			
		</cfif>
	
	</cffunction>
	
</cfcomponent>