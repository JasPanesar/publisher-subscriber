<cfinclude template="plugin/config.cfm" />

<!--- get the lib package --->
<cfset libPackage = request.pluginConfig.getApplication().getValue( "libPackage" ) />

<cfsilent>
	<!--- if an action is passed --->
	<cfif structKeyExists( url, "action" ) AND structKeyExists( url, "id" )>
		
		<!--- get registrar bean --->
		<cfset registrar = libPackage.registrarDAO.readById( url.id ) />
		
		<cfswitch expression="#url.action#">
		
			<!--- if approved --->
			<cfcase value="approve">
				<cfset registrar.set( "status", "approved" ) /> 
				<cfset libPackage.registrarDAO.save( registrar ) />
			</cfcase>
			
			<!--- if deny --->
			<cfcase value="deny">
				<cfset registrar.set( "status", "denied" ) /> 
				<cfset libPackage.registrarDAO.save( registrar ) />
			</cfcase>
			
			<!--- if deny --->
			<cfcase value="remove">
				<cfset libPackage.registrarDAO.delete( registrar ) />
			</cfcase>
		
		</cfswitch> 
		
	</cfif>
</cfsilent>

<!--- results --->
<cfset registrarsQry = libPackage.registrarDAO.list() />

<cfsavecontent variable="body">
<cfoutput>
<h2>#request.pluginConfig.getName()#</h2>

<h3>Your publisher URL's:</h3>
Site URL: #libPackage.proxy.buildMuraURLByCGI()#plugins/#request.pluginConfig.getDirectory()#/proxy.cfc<br />
Proxy URL: #libPackage.proxy.buildMuraURLByCGI()#muraProxy.cfc
<p></p>
<!--- get pending --->
<cfquery name="awaiting" dbtype="query">
	SELECT
		*
	FROM
		registrarsQry
	WHERE
		status = <cfqueryparam cfsqltype="cf_sql_varchar" value="not approved" />
</cfquery>
<h3>Pending (#awaiting.recordcount# records):</h3>
<table class="stripe">
	<thead>
		<tr>
			<th>URL</th>
			<th></th>
		</tr>
	</thead>		
	<tbody>
		<cfloop query="awaiting">
			<tr>
				<td>#subscriberURL#</td>
				<td>
				<a href="?id=#id#&action=approve">Approve</a>
				|
				<a href="?id=#id#&action=deny">Deny</a>
				</td>
			</tr>
		</cfloop>
	</tbody>
</table>

<!--- get pending --->
<cfquery name="approved" dbtype="query">
	SELECT
		*
	FROM
		registrarsQry
	WHERE
		status = <cfqueryparam cfsqltype="cf_sql_varchar" value="approved" />
</cfquery>
<h3>Approved (#approved.recordcount# records):</h3>
<table class="approved">
	<thead>
		<tr>
			<th>URL</th>
			<th></th>
		</tr>
	</thead>		
	<tbody>
		<cfloop query="approved">
			<tr>
				<td>#subscriberURL#</td>
				<td><a href="?id=#id#&action=remove">Remove</a></td>
			</tr>
		</cfloop>
	</tbody>
</table>

<!--- get pending --->
<cfquery name="denied" dbtype="query">
	SELECT
		*
	FROM
		registrarsQry
	WHERE
		status = <cfqueryparam cfsqltype="cf_sql_varchar" value="denied" />
</cfquery>
<h3>Denied (#denied.recordcount# records):</h3>
<table class="stripe">
	<thead>
		<tr>
			<th>URL</th>
			<th></th>
		</tr>
	</thead>		
	<tbody>
		<cfloop query="denied">
			<tr>
				<td>#subscriberURL#</td>
				<td><a href="?id=#id#&action=remove">Remove</a></td>
			</tr>
		</cfloop>
	</tbody>
</table>


</cfoutput>
</cfsavecontent>
<cfoutput>
#application.pluginManager.renderAdminTemplate(body=body,pageTitle=request.pluginConfig.getName())#
</cfoutput>

