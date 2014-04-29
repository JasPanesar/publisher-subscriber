<cfparam name="url.sec" default="" />
<cfparam name="url.id" default="" />
<cfparam name="form.id" default="" />

<cfswitch expression="#url.sec#">

	<cfcase value="save">
		<!--- attempt to get record --->
		<cfset record = libPackage.subscriberDAO.readById( form.id ) />
		<!--- set all values based on form values --->
		<cfset record.setValues( form ) />
		
		<cfdump var="#record.get( 'id' )#" output="console" />
		
		<!--- save the record --->
		<cfset libPackage.subscriberDAO.save( record ) />
		<!--- subscribe request --->
		<cfset libPackage.handler.registerThisSubscriber( form.id ) />
		<cflocation url="index.cfm" />
	</cfcase>

	<cfcase value="delete">
		<!--- get record --->
		<cfset record = libPackage.subscriberDAO.readById( url.id ) />
		<!--- delete the record from the database --->
		<cfset libPackage.subscriberDAO.delete( record ) />
		<cflocation url="index.cfm" />
	</cfcase>

</cfswitch>

<cfoutput>

<!--- if a id is passed then look up the record based on the id --->
<cfif len( url.id )>
	<!--- get the record --->
	<cfset record = libPackage.subscriberDAO.readById( url.id ) />
	<!--- display a message --->
	<cfif NOT record.get( "isNew" )>
		<h3>Subscription to #record.get( "publisherName" )#</h3>
	</cfif>
<cfelse>
	<!--- create an empty record --->
	<cfset record = libPackage.subscriberDAO.new() />
	<h3>New Subscription</h3>
</cfif>

<form id="subscriber" action="index.cfm?sec=save" method="post">
	<input type="hidden" name="id" value="#record.get( "id" )#" />
	<ul>
		<dt>Enabled</dt>
		<dd>
			<select name="enabled">
				<option value="1" <cfif record.get( "enabled" ) IS "1">selected="selected"</cfif>>Yes</option>
				<option value="0" <cfif record.get( "enabled" ) IS "0">selected="selected"</cfif>>No</option>
			</select>
		</dd>
		<dt>Publisher Name</dt>
		<dd><input type="text" name="publisherName" value="#record.get( "publisherName", "" )#" /></dd>
		<dt>Publisher Plugin Proxy URL</dt>
		<dd><input type="text" name="publisherProxyURL" value="#record.get( "publisherProxyURL", "" )#" /></dd>
		<dt>Publisher Mura Proxy URL</dt>
		<dd><input type="text" name="publisherMuraProxyURL" value="#record.get( "publisherMuraProxyURL", "" )#" /></dd>
		<dt>Publisher Username</dt>
		<dd><input type="text" name="publisherUsername" value="#record.get( "publisherUsername", "" )#" /></dd>
		<dt>Publisher Password</dt>
		<dd><input type="text" name="publisherPassword" value="#record.get( "publisherPassword", "" )#" /></dd>
		<dt>Publisher User assigned Site ID</dt>
		<dd><input type="text" name="publisherUserAssignedSiteId" value="#record.get( "publisherUserAssignedSiteId", "" )#" /></dd>
	</ul>
	<input type="submit" value="save" />

</form>

</cfoutput>