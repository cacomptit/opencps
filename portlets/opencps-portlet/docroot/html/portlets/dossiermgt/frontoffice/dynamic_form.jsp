<%@page import="javax.portlet.WindowState"%>
<%@page import="javax.portlet.PortletRequest"%>
<%@page import="com.liferay.portlet.PortletURLFactoryUtil"%>
<%
/**
 * OpenCPS is the open source Core Public Services software
 * Copyright (C) 2016-present OpenCPS community
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
%>

<%@page import="org.opencps.dossiermgt.model.DossierPart"%>
<%@page import="org.opencps.dossiermgt.service.DossierPartLocalServiceUtil"%>
<%@page import="org.opencps.dossiermgt.search.DossierFileDisplayTerms"%>
<%@page import="com.liferay.portal.kernel.servlet.SessionErrors"%>
<%@page import="com.liferay.portal.kernel.servlet.SessionMessages"%>
<%@page import="org.opencps.dossiermgt.search.DossierDisplayTerms"%>
<%@page import="org.opencps.dossiermgt.service.DossierFileLocalServiceUtil"%>
<%@page import="org.opencps.dossiermgt.model.DossierFile"%>
<%@page import="org.opencps.util.WebKeys"%>
<%@page import="org.opencps.util.PortletConstants"%>
<%@ include file="../init.jsp"%>

<%
	boolean success = false;
	
	try{
		success = !SessionMessages.isEmpty(renderRequest) && SessionErrors.isEmpty(renderRequest);
		
	}catch(Exception e){
		
	}
	
	long dossierId = ParamUtil.getLong(request, DossierDisplayTerms.DOSSIER_ID);
	
	long dossierPartId = ParamUtil.getLong(request, DossierFileDisplayTerms.DOSSIER_PART_ID);

	long dossierFileId = ParamUtil.getLong(request, DossierFileDisplayTerms.DOSSIER_FILE_ID);

	DossierPart dossierPart = null;
	
	
	if(dossierPartId > 0){
		try{
			dossierPart = DossierPartLocalServiceUtil.getDossierPart(dossierPartId);
		}catch(Exception e){
			
		}
	}
	
	String formData = StringPool.BLANK;

	String alpacaSchema = dossierPart != null && Validator.isNotNull(dossierPart.getFormScript()) ? 
			dossierPart.getFormScript() : PortletConstants.UNKNOW_ALPACA_SCHEMA;
	
	
	DossierFile dossierFile = null;
	
	if(dossierFileId > 0){
		try{
			dossierFile = DossierFileLocalServiceUtil.getDossierFile(dossierFileId);
		}catch(Exception e){
			
		}
		
		if(dossierFile != null && Validator.isNotNull(dossierFile.getFormData())){
			formData = dossierFile.getFormData();
		}
	}
	
%>

<portlet:actionURL var="updateDynamicFormDataURL" name="updateDynamicFormData"/>

<%-- onSubmit='<%= "event.preventDefault(); " + renderResponse.getNamespace() + "saveDynamicFormData();" %>' --%>

<aui:form 
	name="fm" action="<%=updateDynamicFormDataURL.toString() %>" 
	method="post"
>
	<aui:input name="redirectURL" type="hidden" value="<%=currentURL %>"/>
	<aui:input name="<%=DossierDisplayTerms.DOSSIER_ID %>" type="hidden" value="<%=dossierId %>"/>
	<aui:input name="<%=DossierFileDisplayTerms.DOSSIER_FILE_ID %>" type="hidden" value="<%=dossierFileId %>"/>
	<aui:input name="<%=DossierFileDisplayTerms.DOSSIER_PART_ID %>" type="hidden" value="<%=dossierPartId %>"/>
	<aui:input name="<%=DossierFileDisplayTerms.FORM_DATA %>" type="hidden" value=""/>
	<aui:fieldset id="dynamicForm"></aui:fieldset>
	<aui:fieldset>
		<aui:button type="button" value="save" name="save" cssClass="saveForm"/>
		<aui:button type="button" value="preview" name="preview"/>
		<aui:button type="button" value="create-file" name="create-file"/>
	</aui:fieldset>
</aui:form>

<aui:script>
	var alpacaSchema = <%=alpacaSchema%>;
	var formData = '<%=formData%>';
	var dossierFileId = '<%=dossierFileId%>';
	
	AUI().ready(function(A){
		
		if(alpacaSchema.options != 'undefined' && alpacaSchema.schema != 'undefined'){
			
			if(formData != ''){
				alpacaSchema.data = JSON.parse(formData);
			}
			
			//Overwrite function
			alpacaSchema.postRender = function(control){
				$(".saveForm").click(function(e) {
					var formData = control.getValue();
					$("#<portlet:namespace />formData" ).val(JSON.stringify(formData));
					$("#<portlet:namespace />fm" ).submit();
			    });
			};
		
		}
		var el = $("#<portlet:namespace/>dynamicForm");
		
		Alpaca(el, alpacaSchema);
		
		var createReportBtn = A.one('#<portlet:namespace/>create-file');
		if(createReportBtn){
			createReportBtn.on('click', function(){
				<portlet:namespace/>createReport(dossierFileId);
			});
		}
	});
	
	Liferay.provide(window, '<portlet:namespace/>createReport', function(dossierFileId) {
		var A = AUI();
		var portletURL = Liferay.PortletURL.createURL('<%= PortletURLFactoryUtil.create(request, WebKeys.DOSSIER_MGT_PORTLET, themeDisplay.getPlid(), PortletRequest.ACTION_PHASE) %>');
		portletURL.setParameter("javax.portlet.action", "createReport");
		portletURL.setWindowState('<%=WindowState.NORMAL%>');
		A.io.request(
			portletURL.toString(),
			{
			    dataType : 'json',
			    data:{    	
			    	<portlet:namespace/>dossierFileId : dossierFileId,
			    },   
			    on: {
			        success: function(event, id, obj) {
						var instance = this;
						var res = instance.get('responseData');
						
						var fileExportDir = res.fileExportDir;
						console.log(fileExportDir);

					},
			    	error: function(){}
				}
			}
		);
	},['aui-io','liferay-portlet-url']);
	
	Liferay.provide(window, '<portlet:namespace/>closeDialog', function() {
		var dialog = Liferay.Util.getWindow('<portlet:namespace/>dynamicForm');
		dialog.destroy(); // You can try toggle/hide whate
	});
	
	Liferay.provide(window, '<portlet:namespace/>saveDynamicFormData', function() {
		var A = AUI();
		var uri = A.one('#<portlet:namespace/>fm').attr('action');
		var configs = {
             method: 'POST',
             form: {
                 id: '#<portlet:namespace/>fm'
             },
             on: {
             	failure: function(event, id, obj) {
             		console.log(event);
				},
				success: function(event, id, obj) {
					var response = this.get('responseData');
					console.log(response);
					
				},
                complete: function(event, id, obj){
                	console.log(event);
                }
             }
        };
	            
	    A.io.request(uri, configs); 
	},['aui-io']);
</aui:script>
