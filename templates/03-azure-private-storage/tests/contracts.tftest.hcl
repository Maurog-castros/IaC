mock_provider "azurerm" {}
variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  storage_name    = "iacdemotest"
}
run "private_by_default" {
  command = plan
  assert {
    condition     = !azurerm_storage_account.this.public_network_access_enabled && !azurerm_storage_account.this.shared_access_key_enabled && !azurerm_storage_account.this.allow_nested_items_to_be_public
    error_message = "Storage no debe admitir red pública, shared keys ni blobs públicos."
  }
  assert {
    condition     = azurerm_storage_account.this.account_replication_type == "ZRS"
    error_message = "Conservar redundancia zonal."
  }
}
run "reject_invalid_name" {
  command = plan
  variables { storage_name = "INVALID-NAME" }
  expect_failures = [var.storage_name]
}
