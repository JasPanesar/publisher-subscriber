<cfparam name="url.sec" default="" />
<cfinclude template="plugin/config.cfm" />

<!--- get the lib package --->
<cfset libPackage = request.pluginConfig.getApplication().getAllValues() />

<cfsavecontent variable="body">
<cfoutput>
<h2>#request.pluginConfig.getName()#</h2>

<cfswitch expression="#url.sec#">

	<cfcase value="edit,save,delete">
		<cfinclude template="dsp/edit.cfm" />
	</cfcase>

	<cfdefaultcase>
		<cfinclude template="dsp/list.cfm" />
	</cfdefaultcase>

</cfswitch>
</cfoutput>
</cfsavecontent>
<cfoutput>
#application.pluginManager.renderAdminTemplate(body=body,pageTitle=request.pluginConfig.getName())#
</cfoutput>

