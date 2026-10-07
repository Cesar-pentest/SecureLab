terraform{
	required_providers {
		azurerm = {
			source = "hashicorp/azurerm"
			version = "~> 4.0"
		}
	}
}

provider azurerm {
	features {}
	subscription_id = "31b7b62d-a7dc-4303-a873-08dc950dc94f"
}
