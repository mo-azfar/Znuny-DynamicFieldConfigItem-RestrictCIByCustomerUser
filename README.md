# Znuny-DynamicFieldConfigItem-RestrictCIByCustomerUser
- Restrict the value of dynamic field config item based on customer user
- Required Znuny 6.4.3 and addon Znuny-DynamicFieldConfigItem 6.4.1 (at least)

1. Create dynamic field config item.
2. Update System Configuration > Ticket::Acl::Module###5-ZnunyRestrictCIByCustomerUser

		Action = Screen where this ACL will be apply. (Support multiple action by (+) button)
		
		CIFieldNameReference = Key field in Config Item that hold customer user id. By default, Owner.
		
		DeplState = Config item deployment state (Support multiple deployment state by (+) button). If empty, deployment state will be taken from defined Dynamic Field config itself.
	
		RelatedDynamicField  = DynamicField ConfigItem name that will use this ACL to restrict its config item.
	
		

![](https://github.com/mo-azfar/Znuny-DynamicFieldConfigItem-RestrictCIByCustomerUser/blob/main/DFCI.gif)
