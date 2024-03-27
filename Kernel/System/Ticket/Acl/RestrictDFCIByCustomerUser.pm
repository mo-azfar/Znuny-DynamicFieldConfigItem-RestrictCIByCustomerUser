# --
# Copyright (C) 2024 mo-azfar, https://github.com/mo-azfar
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Ticket::Acl::RestrictDFCIByCustomerUser;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Log',
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

    #get paremeter
    my %GetParam;
    for my $Needed (qw( CIFieldNameReference RelatedDynamicField Action ObjectType ))
    {
        return 1 if !$Param{Config}->{$Needed};
    }

    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $ConfigItemObject     = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $DynamicFieldObject   = $Kernel::OM->Get('Kernel::System::DynamicField');

    my $Action = $Param{Checks}->{Frontend}->{Action} || '';

    return 1 if !$Action;

    #only generate acl based on define frontend action
    return 1 if !$Param{Config}->{Action}->{$Action};

    DYNAMICFIELD:
    for ( @{ $Param{Config}->{RelatedDynamicField} } )
    {
        my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
            Name => $_,
        );

        next DYNAMICFIELD if !$DynamicField->{Config}->{ConfigItemClass};

        my @ClassIDs;
        my @DeplStateIDs;
        my @InciStateIDs;

        #get config item class id based on dynamic field
        my $ClassID = $GeneralCatalogObject->ItemGet(
            Class => 'ITSM::ConfigItem::Class',
            Name  => $DynamicField->{Config}->{ConfigItemClass},
        );

        push @ClassIDs, $ClassID->{ItemID};

        #get deployment state
        if ( @{ $Param{Config}->{DeplState} } )
        {
            #get config item deployment state id based on config
            for ( @{ $Param{Config}->{DeplState} } )
            {
                my $DeplStateID = $GeneralCatalogObject->ItemGet(
                    Class => 'ITSM::ConfigItem::DeploymentState',
                    Name  => $_,
                );
                push @DeplStateIDs, $DeplStateID->{ItemID};
            }
        }
        else
        {
            #get config item deployment state id based on dynamic field
            for ( @{ $DynamicField->{Config}->{DeplStates} } )
            {
                my $DeplStateID = $GeneralCatalogObject->ItemGet(
                    Class => 'ITSM::ConfigItem::DeploymentState',
                    Name  => $_,
                );
                push @DeplStateIDs, $DeplStateID->{ItemID};
            }
        }

        #get incident state
        if ( @{ $Param{Config}->{InciState} } )
        {
            #get config item deployment state id based on config
            for ( @{ $Param{Config}->{InciState} } )
            {
                my $DeplStateID = $GeneralCatalogObject->ItemGet(
                    Class => 'ITSM::Core::IncidentState',
                    Name  => $_,
                );
                push @InciStateIDs, $DeplStateID->{ItemID};
            }
        }

        my $Customer;
        my $Properties;

        #customer user based
        if ( $Param{Config}->{ObjectType} eq 1 )
        {
            $Properties = "UserLogin";
            $Customer   = $Param{Checks}->{CustomerUser}->{UserLogin};
        }

        #customer company based
        elsif ( $Param{Config}->{ObjectType} eq 2 )
        {
            $Properties = "UserCustomerID";
            $Customer   = $Param{Checks}->{CustomerUser}->{UserCustomerID};
        }

        #search config item
        my $ConfigItemIDs = $ConfigItemObject->ConfigItemSearchExtended(
            ClassIDs     => [@ClassIDs],
            DeplStateIDs => [@DeplStateIDs],
            InciStateIDs => [@InciStateIDs],
            What         => [

                # each array element is a and condition
                {
                    "[%]{'Version'}[%]{'$Param{Config}->{CIFieldNameReference}'}[%]{'Content'}" => [$Customer],
                }
            ],

        );

        my $ACLName = 'ACL_' . $Customer . '_' . $_;

        $Param{Acl}->{$ACLName} = {
            Properties => {
                CustomerUser => {
                    $Properties => [$Customer],
                },
            },

            # return possible options (white list)
            Possible => {
                Ticket => {
                    'DynamicField_' . $_ => [ '', @{$ConfigItemIDs} ],
                },
            },
        };

    }

    return 1;
}

1;
