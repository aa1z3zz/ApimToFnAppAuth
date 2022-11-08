# Authenticating from Functions to APIM with a Managed Identity

This is example code showing how to authenticate from an Azure function to Azure API Management (APIM) using a managed identity.

## Features

This example provides the following features:

* Private backend Azure Function App.
* Azure API Management instance.
* Public Untrusted Azure Function App.
* Public Trusted Azure Function App.

### Azure Function to APIM Authentication

For the Function App to APIM authentication use case, the most important parts can be found in these files:

* APIM Policy definition: [apim.tf](terraform/apim.tf)
* Azure Function C# code: [Test.cs](src/Functions/PublicFunction/Test.cs)

The Azure Function code follows these steps:

1. Get the user assigned managed identity.
1. Generate a JWT from the user assigned managed identity.
1. Make a call to the APIM end point, passing the JWT in the Authorization Bearer header.

The APIM Policy has the following attributes:

* It uses the `validate-azure-ad-token` policy type.
* It specifies that only the client ID of the user assigned managed identity for the trusted public function app can access the operation. It does this by including it in the `client-application-ids` list.

## Getting Started

### Prerequisites

- The Azure Functions Core Tools CLI: [Download](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=v4%2Cwindows%2Ccsharp%2Cportal%2Cbash#install-the-azure-functions-core-tools)
- HashiCorp Terraform CLI: [Download](https://www.terraform.io/downloads)
- Azure CLI: [Download](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli#install-or-update)
- An Azure Subscription: [Free Account](https://azure.microsoft.com/en-gb/free/search/)

### Installation

- Clone this repository to your local machine

### Quickstart

We deploy the infrastructure using Terraform first. Follow these steps to login to Azure and apply the Terraform.

1. Open your console of choice and navigate to the the `/terraform` folder.
1. Run `az login` to login to your Azure Account.
1. Run `az account set --subscription [my-subscription]` where [my-subscription] is the name of your subscription.
1. Run `terraform init` to pull down the providers.
1. Run `terraform apply`. Take a look at the plan it generates and then type `yes` to run the plan.
1. Take note of the outputs from Terraform as you'll need these later.
1. Take a look at the resource groups and resources in the Azure portal.

Once you are happy with the deployed resources, we need to deploy the function code. Terraform will output a script in the `deploy_script` output to help with this, or you can follow these steps.

1. Navigate to the `/src/Functions/PrivateFunction` folder.
1. Deploy the private function by running `func azure functionapp publish [private-function-name] --csharp` where [private-function-name] is the name of your private function. This will have been outputted from terraform as `private_function_name`.
1. Navigate to the `/src/Functions/PublicFunction` folder.
1. Deploy the untrusted public function by runnng `func azure functionapp publish [public-untrusted-function-name] --csharp` where [public-untrusted-function-name] is the name of your untrusted public function. This will have been outputted from terraform as `public_untrusted_function_name`.
1. Deploy the trusted public function by runnung `func azure functionapp publish [public-trusted-function-name] --csharp` where [public-trusted-function-name] is the name of your trusted public function. This will have been outputted from terraform as `public_trusted_function_name`.

## Demo

To run the demo, follow these steps:

1. Navigate to the untrusted function app, using the url in `public_untrusted_demo_url`. You should see a 401 error like this: `{ "statusCode": 401, "message": "Invalid Azure AD JWT" }`.
2. Navigate to the trusted function app, using the url in `public_trusted_demo_url`.You should see a successful call like this: `{"message":"Hello from the Private Function!","dateOfMessage":"2022-11-08T12:14:59.4735675+00:00"}`.

As you can see the untrusted function does not have it's managed identity specified in the APIM policy, so it is not authenticated. More details on the policy can be found [here](https://learn.microsoft.com/en-us/azure/api-management/api-management-access-restriction-policies#ValidateAAD).

## Resources

- [Validate AAD APIM Policy](https://learn.microsoft.com/en-us/azure/api-management/api-management-access-restriction-policies#ValidateAAD)
- [Managed Identity for Linux Function App Storage has limited support](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference?tabs=blob#connecting-to-host-storage-with-an-identity-preview)
- [Azure Functions Core Tools reference](https://learn.microsoft.com/en-us/azure/azure-functions/functions-core-tools-reference?tabs=v2#func-azure-functionapp-fetch-app-settings)