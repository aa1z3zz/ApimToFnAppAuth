/*
The API we will use to test that leverages an App Registration, so we can use groups. It is configured with a backend that points to our Private Function App.
*/
resource "azurerm_api_management_api" "trusted_group" {
  name                = "trusted-group"
  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.demo.name
  revision            = "1"
  display_name        = "Trusted Group Auth API"
  path                = "trusted-group"
  protocols           = ["https"]

  service_url = "https://${azurerm_windows_function_app.private.default_hostname}/api"
}

/*
The operation on our API that we will use to test. This maps to the /test method on our Function App.
*/
resource "azurerm_api_management_api_operation" "trusted_group" {
  operation_id        = "test"
  api_name            = azurerm_api_management_api.trusted_group.name
  api_management_name = azurerm_api_management.demo.name
  resource_group_name = azurerm_resource_group.apim.name
  display_name        = "Test Operation"
  method              = "GET"
  url_template        = "/test"
  description         = "Get test data from the private function."

  response {
    status_code = 200
  }
}

/*
This is the policy that will be applied to our operation.
We use the `validate-azure-ad-token` policy to validate the JWT token that is passed in the Authorization Bearer header. 
This policy uses the Authorization Bearer header by default, but can be customised if needed.
We specifiy the Client ID of the User Assigned Managed Identity that we created for our Public Azure Function App in the `client-apllication-ids` list.
Further details on the policy can be found here: https://learn.microsoft.com/en-us/azure/api-management/api-management-access-restriction-policies#ValidateAAD

We also use the `authentication-managed-identity` policy to get a JWT token for the private function app.
This policy specifies the resource as the client Id of our AzureAD App Registration, which will scope the token to our private function app
It also specifies the client-id of our user assigned managed identity to ensure it chooses the correct identity.
We then take the token and add it to the Authentication Bearer header using the `set-header` policy.

NOTE: This policy could be applied at the API level instead of the individual operation.
*/
resource "azurerm_api_management_api_operation_policy" "trusted_group" {
  api_name            = azurerm_api_management_api_operation.trusted_group.api_name
  api_management_name = azurerm_api_management_api_operation.trusted_group.api_management_name
  resource_group_name = azurerm_api_management_api_operation.trusted_group.resource_group_name
  operation_id        = azurerm_api_management_api_operation.trusted_group.operation_id

  xml_content = <<XML
<policies>
  <inbound>
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Access token is missing or invalid." require-scheme="Bearer">
     <openid-config url="https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0/.well-known/openid-configuration" />
     <audiences>
         <audience>api://${var.prefix}-apim</audience>
     </audiences>
     <issuers>
         <issuer>https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/</issuer>
     </issuers>
     <!--<required-claims>
         <claim name="roles" match="any">
             <value>example</value>
         </claim>
     </required-claims>-->
    </validate-jwt> 
    <authentication-managed-identity resource="${azuread_application.function_private.application_id}" client-id="${azurerm_user_assigned_identity.apim.client_id}" output-token-variable-name="msi-access-token" ignore-error="false"/>
    <set-header name="Authorization" exists-action="override">
      <value>@("Bearer " + (string)context.Variables["msi-access-token"])</value>
    </set-header>
  </inbound>
</policies>
XML
}