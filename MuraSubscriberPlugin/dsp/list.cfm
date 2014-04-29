<!--- results --->
<cfset subscriptionsQry = request.pluginConfig.getApplication().getValue("subscriberDAO").list() />

<cffunction name="getStatus">
	<cfargument name="publisherURL" type="string" required="true" />
	
	<cfset var webserviceResults = "" />
	
	<!--- attempt to get status --->
	<cftry>
	<cfinvoke 
		method="status"
		returnvariable="webserviceResults"
		webservice="#trim(arguments.publisherURL)#?wsdl">
		<cfinvokeargument name="subscriberURL" value="#request.pluginConfig.getSetting( "yourURL" )#/plugins/#request.pluginConfig.getDirectory()#/proxy.cfc" />
		<cfinvokeargument name="subscriberId" value="#request.pluginConfig.getPluginId()#" />
	</cfinvoke>
	<cfcatch>
	</cfcatch>
	</cftry>
	<cfreturn webserviceResults />
</cffunction>

<cfoutput>
<a href="index.cfm?sec=edit">Subscribe to a publisher</a>
<cfif NOT subscriptionsQry.recordcount>
	<h3>You are currently not subscribed to anything at the moment.</h3>
<cfelse>
	<table>
		<thead>
			<tr>
				<th>Publisher Name</th>
				<th>Enabled?</th>
				<th colspan="2">Status</th>
			</tr>
		</thead>
		<tbody>
			<cfloop query="subscriptionsQry">
				<tr>
					<td>#publisherName#</td>
					<td>#yesNoFormat( enabled )#</td>
					<th>
					<cfset pubStatus = getStatus( publisherProxyURL ) />
					<cfif pubStatus IS "approved">
						<font color="green"><strong>#ucase(pubStatus)#</strong></font>
					<cfelseif pubStatus IS "denied">
						<font color="red"><strong>#ucase(pubStatus)#</strong></font>
					<cfelse>
						<font color="grey"><strong>#ucase(pubStatus)#</strong></font>
					</cfif>
					</th>
					<td><a href="index.cfm?sec=edit&id=#id#">Edit</a> | <a href="index.cfm?sec=delete&id=#id#">Delete</a></td>
				</tr>
			</cfloop>
		</tbody>
	</table>
</cfif>
</cfoutput>