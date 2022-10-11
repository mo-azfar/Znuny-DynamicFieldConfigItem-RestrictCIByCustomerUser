# --
# Copyright (C) 2022 mo-azfar, https://github.com/mo-azfar/Znuny-DynamicFieldConfigItem-RestrictCIByCustomerUser/
#
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Acl::ZnunyRestrictCIByCustomerUser;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);


sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;
	
	# check needed stuff
    for (qw(Config Acl)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

	return 1 if !$Param{Checks}->{CustomerUser}->{UserLogin};
	return 1 if !$Param{Config}->{CIFieldNameReference};
	return 1 if !@{$Param{Config}->{RelatedDynamicField}};
	return 1 if !@{$Param{Config}->{Action}};
	
	my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
	my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
	my $CustomerUserID = $Param{Checks}->{CustomerUser}->{UserLogin};
	
	my $ACLGenerate = 0;
    ACL:
	
	#only generate acl based on define frontend action
	for (@{$Param{Config}->{Action}})
	{
		next if $Param{Checks}->{Frontend}->{Action} ne $_;
		
		if ( $Param{Checks}->{Frontend}->{Action} eq $_ ) {
            $ACLGenerate = 1;
            last ACL;
        }
	}
	
	if ( $ACLGenerate )
	{	
		for (@{$Param{Config}->{RelatedDynamicField}})
		{
			my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
				Name => $_,
			);
			
			next if !$DynamicField->{Config}->{ConfigItemClass};
			
			my @ClassIDs;
			my @DeplStateIDs;
			
			#get config item class id based on dynamic field	
			my $ClassID = $GeneralCatalogObject->ItemGet(
				Class => 'ITSM::ConfigItem::Class',
				Name  => $DynamicField->{Config}->{ConfigItemClass},
			);
			
			push @ClassIDs, $ClassID->{ItemID};
			
			#get config item deployment state id based on dynamic field
			for ( @{$DynamicField->{Config}->{DeplStates}} )
			{
				my $DeplStateID = $GeneralCatalogObject->ItemGet(
					Class => 'ITSM::ConfigItem::DeploymentState',
					Name  => $_,
				);
				push @DeplStateIDs, $DeplStateID->{ItemID};
			}
			
			#search config item
			my $ConfigItemIDs = $ConfigItemObject->ConfigItemSearchExtended(
				ClassIDs => [@ClassIDs], 
				DeplStateIDs => [@DeplStateIDs], 
				What => [                                               
					# each array element is a and condition
					{			
						"[%]{'Version'}[%]{'$Param{Config}->{CIFieldNameReference}'}[%]{'Content'}" => [$CustomerUserID],				
					}
				],
		
			);
	
			my $ACLName = 'ACL_'.$CustomerUserID.'_'.$_;
	
			$Param{Acl}->{$ACLName} = {
				Properties => {
					CustomerUser => {
						UserLogin => [ $CustomerUserID ],
					},
				},
		
				# return possible options (white list)
				Possible => {
					Ticket => {
						'DynamicField_'.$_ => ['', @{$ConfigItemIDs}],
					},
				},
			};
			
			
		}
		
		
	}
	
    return 1;
}

1;
