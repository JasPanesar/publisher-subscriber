<cfcomponent extends="mura.plugin.pluginGenericEventHandler">
	
	<cfset variables.objsCollection = "" />
	
	<cffunction name="onApplicationLoad" output="false" returntype="any">
		<cfargument name="event" /> 
		
		<cfset variables.objsCollection = pluginConfig.getApplication() />
		<cfset variables.objsCollection.setValue( "subscriberDAO", createObject( "component", "plugins.#pluginConfig.getDirectory()#.lib.com.blueriver.data.subscriberDAO" ).init() ) />
		<cfset variables.objsCollection.setValue( "subscriberService", createObject( "component", "plugins.#pluginConfig.getDirectory()#.lib.com.blueriver.service.subscriberService" ).init() ) />
		<cfset variables.objsCollection.setValue( "translatorService", createObject( "component", "plugins.#pluginConfig.getDirectory()#.lib.com.blueriver.service.translatorService" ).init() ) />
		<cfset variables.objsCollection.setValue( "builderService", createObject( "component", "plugins.#pluginConfig.getDirectory()#.lib.com.blueriver.service.builderService" ).init() ) />
		<cfset variables.objsCollection.setValue( "proxy", createObject( "component", "plugins.#pluginConfig.getDirectory()#.proxy" ) ) />
		<cfset variables.objsCollection.setValue( "handler", this ) />
		
		<!--- autowiring --->
		<cfset variables.objsCollection.getValue( property:"translatorService", autowire:true ) />
		<cfset variables.pluginConfig.addEventHandler(this)>		
	</cffunction>

	<cffunction name="onContentEdit" output="true" returntype="any">
		<cfargument name="event" />
		
		<cfset var local = structNew() />
		
		<cfset variables.objsCollection = pluginConfig.getApplication() />
		
		<cfset local.subscriberDAO = variables.objsCollection.getValue( property:"subscriberDAO", autowire:true ) />
		<!--- get the publisher --->
		<cfset local.publisher = local.subscriberDAO.readById( event.getValue( "contentBean" ).getRemoteSourceURL() ) />
		
		<cfoutput>
		
		<!--- js --->
		<cfsavecontent variable="local.js">
			<cfoutput>
				<script language="javascript">
					// on load
					jQuery(document).ready(function()
					{
						<!--- show a message that states that this page is automatically updated by the subscriber --->
						<cfif event.getValue( "contentBean" ).getValue( "autoUpdateSubscriberPage" ) IS "Yes">
							jQuery("##msg").append( "<p class='notice'><img src='/plugins/#pluginConfig.getDirectory()#/images/icons/error.png'> This content is set to auto-update from a remote publisher (#local.publisher.get( "PublisherName" )#). Any updates made locally will be overwritten. To change this setting, go to the Mura Subscriber Plugin tab.</p>" )
						</cfif>
					});
					

					function getActiveContent() 
					{
						// get the publisher id 
						var publisherId = jQuery("##publisher").val();

						// hide the load button
						jQuery("##loadButton").hide();						
						jQuery("##loadIcon").show();
					
						// look locally for the id associated to the publisher
						jQuery.getJSON( '/plugins/#pluginConfig.getDirectory()#/proxy.cfc?method=getPublisherActiveContent&customFormat=json&PublisherId=' + publisherId,
							function(j)
							{
								options = '<option value="">-- SELECT ONE --</option>';
								// create the options
								//alert(j)
								for (var i = 0; i < j.recordcount; i++) {
        							options += '<option value="' + j.data.siteid[i] + '|' + j.data.contentid[i] + '">' + j.data.filename[i] + '</option>';
							    }
								// assign the options 
							    jQuery("##subscriberRemoteId").html(options);
								// select the current key pair
								jQuery("##subscriberRemoteId option[value='#event.getValue( 'contentBean' ).getRemoteId()#']").attr("selected", "selected"); 
							
								// show the load button
								jQuery("##loadButton").show();						
								jQuery("##loadIcon").hide();
							}
						);
					}
				</script>
			</cfoutput>		
		</cfsavecontent>
		<cfhtmlhead text="#local.js#" />
		
		<p></p>
		
		
		<!--- *************************************************** --->	
		<!--- only show up if the remote id is present --->
		<!--- *************************************************** --->
		<!--- might want to make this a little more robust --->
		<cfif len( event.getValue( "contentBean" ).getRemoteId() )>
			
			<!--- only render if there is a record found --->
			<cfif NOT local.publisher.get( "isNew" )>		
				<!--- get active content --->
				<cfinvoke webservice="#trim(local.publisher.get( 'PublisherMuraProxyURL' ))#?wsdl"
					method="login"
					returnVariable="local.login">
					<cfinvokeargument name="username" value="#local.publisher.get( 'publisherUsername' )#">
					<cfinvokeargument name="password" value="#local.publisher.get( 'publisherPassword' )#">
					<cfinvokeargument name="siteID" value="#local.publisher.get( 'publisherUserAssignedSiteId ')#">
				</cfinvoke>
				
				<cfset local.args = structNew() />
				<cfset local.args.contentId = listGetAt(event.getValue( "contentBean" ).getRemoteId(), 2, "|") />
				<cfset local.args.siteId = listGetAt(event.getValue( "contentBean" ).getRemoteId(), 1, "|") />
				<cfinvoke webservice="#trim(local.publisher.get( 'PublisherMuraProxyURL' ))#?wsdl"
					method="call"
					returnVariable="local.webserviceLastUpdateResults">
					<cfinvokeargument name="serviceName" value="publisher">
					<cfinvokeargument name="methodName" value="getLastUpdate">
					<cfinvokeargument name="authToken" value="#local.login#">
					<cfinvokeargument name="args" value="#local.args#" />
				</cfinvoke>
				
				<!--- site id --->
				<cfset local.siteId = listGetAt(event.getValue( "contentBean" ).getRemoteId(), 1, "|") />
				<!--- parent id --->
				<cfset local.parentId = event.getValue( "contentBean" ).getParent().getContentId() />
				<!--- content id --->
				<cfset local.contentId = listGetAt(event.getValue( "contentBean" ).getRemoteId(), 2, "|") />
				
				<!--- last updated --->
				<p>
					Last Updated: #dateFormat( local.webserviceLastUpdateResults, "mm/dd/yyyy" )# | #timeformat( local.webserviceLastUpdateResults, "h:mm:ss tt" )#
					<cfif len( event.getValue( "contentBean" ).getRemotePubDate() ) AND dateCompare( event.getValue( "contentBean" ).getRemotePubDate(), local.webserviceLastUpdateResults) LT 0>
						<font color="red">NEW VERSION AVAILABLE</font><br />
					</cfif>
				</p>
				
				<ul>
					<li><a href="javascript:preview('/#event.getValue( 'contentBean' ).getSiteId()#/index.cfm/#event.getValue( 'contentBean' ).getFileName()#/','');"><i class="icon-eye-open"></i> View Publisher's Content</a></li>
					<li><a href="/plugins/#pluginConfig.getDirectory()#/proxy.cfc?method=localNewRequest&builderType=content&publisherId=#local.publisher.get( 'id' )#&subscriberId=#pluginConfig.getPluginId()#&remoteId=#local.contentId#&remoteParentId=#local.contentId#&remoteSiteId=#local.siteId#&subscriberSiteId=#event.getValue( 'siteId' )#&topId=#event.getValue( 'contentBean' ).getContentId()#&publisherProxyURL=#event.getValue( 'contentBean' ).getRemoteURL()#"><i class="icon-refresh"></i> Get Updated Content</a></li>
				</ul>
			</cfif>
			
		</cfif>
		
		<!--- get extendset id--->
		<cfset id = application.classExtensionManager.getSubTypeByName( event.getValue( 'contentBean' ).getType(), 'Default' , event.getValue( 'contentBean' ).getSiteId() ).getExtendSetByName( 'Mura Subscriber' ).getExtendSetId() />
		<input type="hidden" value="#trim( id )#" name="extendSetID" />
		<dd>
			<dl>
				<dt>Select Publisher</dt>
				<dd>
					<!--- get subscriptions --->
					<cfset local.subscriptions = local.subscriberDAO.listByEnabled( 1 ) />
					<!--- loop out active subscriptions --->
					<select id="publisher" name="publisher" onchange="jQuery('##remoteURL').val(this.options[this.selectedIndex].value);getActiveContent();")>
						<option>-- SELECT ONE --</option>
						<cfloop query="local.subscriptions">
							<option value="#id#" <cfif local.publisher.get( "id" ) IS id>selected="selected"</cfif>>#publisherName#</option>
						</cfloop>
					</select>
				</dd>
				<dt>Subscribe to Content</dt>	
				<dd>
					<!--- loop out active content --->
					<select id="subscriberRemoteId" name="subscriberRemoteId" onchange="document.contentForm.remoteID.value=this.options[this.selectedIndex].value;")>
						<option>-- HIT THE LOAD BUTTON --</option>
					</select>
					<input id="loadButton" type="button" value="load" onclick="getActiveContent();" />
					<img id="loadIcon" src="/admin/assets/images/ajax-loader-sm.gif" style="display: none;">
				</dd>				
				<dt>Include Children?</dt>
				<dd><input id="subscribeToAllChildPages" name="subscribeToAllChildPages" value="No" <cfif event.getValue( "contentBean" ).getValue( "subscribeToAllChildPages" ) IS "No" or event.getValue( "contentBean" ).getValue( "subscribeToAllChildPages" ) IS "">checked="checked"</cfif> type="radio"> No <input id="subscribeToAllChildPages" name="subscribeToAllChildPages" <cfif event.getValue( "contentBean" ).getValue( "subscribeToAllChildPages" ) IS "Yes">checked="checked"</cfif> value="Yes" type="radio"> Yes </dd>	
				<dt>Auto update?</dt>
				<dd><input id="autoUpdateSubscriberPage" name="autoUpdateSubscriberPage" <cfif event.getValue( "contentBean" ).getValue( "autoUpdateSubscriberPage" ) IS "No">checked="checked"</cfif> value="No" type="radio"> No <input id="autoUpdateSubscriberPage" name="autoUpdateSubscriberPage" value="Yes" <cfif event.getValue( "contentBean" ).getValue( "autoUpdateSubscriberPage" ) IS "Yes" or event.getValue( "contentBean" ).getValue( "autoUpdateSubscriberPage" ) IS "">checked="checked"</cfif> type="radio"> Yes </dd>
			</dl>
		</dd>
					
		
		</cfoutput>
		
	</cffunction>
	
	<cffunction name="onBeforeContentSave" output="false" returntype="any">
		<cfargument name="event" />
		
		<cfif event.getValue( "newBean" ).getIsNew()>
			<cfset event.setValue( "triggerSubscriptionUpdate", true ) />
		</cfif>
		
	</cffunction>
	
	<cffunction name="onAfterContentSave" output="false" returntype="any">
		<cfargument name="event" />
		
		<cfset var local = structNew() />
		
		<cfset variables.objsCollection = pluginConfig.getApplication() />	
		
		<cfset local.subscriberDAO = variables.objsCollection.getValue( property:"subscriberDAO", autowire:true ) />			
		<cfset local.subscriberService = variables.objsCollection.getValue( property:"subscriberService", autowire:true ) />			
					
		<cfif ( event.valueExists( "triggerSubscriptionUpdate" ) AND event.getValue( "triggerSubscriptionUpdate" ) ) OR event.getValue( "autoUpdateSubscriberPage" ) IS "Yes" AND event.getValue( "preventEventRefire" ) IS NOT "true">
		
			<!--- get the publisher --->
			<cfset local.publisher = local.subscriberDAO.readById( event.getValue( "contentBean" ).getRemoteURL() ) />
		
			<!--- if the publisher is not new and the remote id is full then attempt a pull from the publisher --->
			<!--- only run if the extended attribute autoUpdateSubscriberPage is "Yes" --->
			<cfif len( event.getValue( "contentBean" ).getRemoteId() ) AND NOT local.publisher.get( "isNew" )>
				<cfset local.subscriberService.newRequest(
						builderType: "content",
						publisherProxyURL: local.publisher.get( "publisherProxyURL" ),
						subscriberId: pluginConfig.getPluginId(),
						remoteParentid: listGetAt(event.getValue( "contentBean" ).getRemoteId(), 2, "|"),
						remoteId: listGetAt(event.getValue( "contentBean" ).getRemoteId(), 2, "|"),
						remoteSiteId: listGetAt(event.getValue( "contentBean" ).getRemoteId(), 1, "|"),
						localSiteId: event.getValue( "contentBean" ).getSiteId(),
						forceRequest: true
					) />			
			</cfif>
		
		</cfif>
	
	</cffunction>
	
	<cffunction name="registerThisSubscriber" access="public">
		<cfargument name="id" type="string" required="true" />
		
		<cfset var local = structNew() />
		
		<cfset local.subscriberDAO = variables.objsCollection.getValue( property:"subscriberDAO", autowire:true ) />			
					
		<cfset local.url = findNoCase( "/admin/", cgi.http_referer ) />
		<cfset local.url = pluginConfig.getSetting( 'yourURL' ) & "/plugins/#pluginConfig.getDirectory()#/proxy.cfc" />
		<!--- get the publisher --->
		<cfset local.publisher = local.subscriberDAO.readById( arguments.id ) />
		
		<Cfdump var="#arguments.id#" output="console" />
		
		<cfhttp url="#local.publisher.get( 'publisherProxyURL' )#" method="get" throwonerror="yes">
			<cfhttpparam type="URL" name="method" value="register" />
			<cfhttpparam type="URL" name="subscriberURL" value="#local.url#" />
			<cfhttpparam type="URL" name="subscriberId" value="#pluginConfig.getPluginId()#" />
		</cfhttp>
		
	</cffunction>

</cfcomponent>

