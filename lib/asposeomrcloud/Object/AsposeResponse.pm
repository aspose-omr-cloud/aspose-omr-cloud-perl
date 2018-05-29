=begin comment

Copyright (c) 2018 Aspose Pty Ltd. All Rights Reserved.

Licensed under the MIT (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

      https://github.com/aspose-omr-cloud/aspose-omr-cloud-perl/blob/master/LICENSE

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.



Aspose.OMR for Cloud API Reference

Aspose.OMR for Cloud helps performing optical mark recognition in the cloud

OpenAPI spec version: 1.1

Generated by: https://github.com/swagger-api/swagger-codegen.git

=end comment

=cut

#
# NOTE: This class is auto generated by the swagger code generator program. 
# Do not edit the class manually.
# Ref: https://github.com/swagger-api/swagger-codegen
#
package asposeomrcloud::Object::AsposeResponse;

require 5.6.0;
use strict;
use warnings;
use utf8;
use JSON qw(decode_json);
use Data::Dumper;
use Module::Runtime qw(use_module);
use Log::Any qw($log);
use Date::Parse;
use DateTime;

use base ("Class::Accessor", "Class::Data::Inheritable");


#
#The basic AsposeResponse response class kept from the old Aspose for Cloud Platform. We keep this base class and use it because most probably users are already using it to get API responses. The plan in future is to get rid of this name, but who knows when ?!
#
# NOTE: This class is auto generated by the swagger code generator program. Do not edit the class manually.
# REF: https://github.com/swagger-api/swagger-codegen
#

=begin comment

Copyright (c) 2018 Aspose Pty Ltd. All Rights Reserved.

Licensed under the MIT (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

      https://github.com/aspose-omr-cloud/aspose-omr-cloud-perl/blob/master/LICENSE

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.



Aspose.OMR for Cloud API Reference

Aspose.OMR for Cloud helps performing optical mark recognition in the cloud

OpenAPI spec version: 1.1

Generated by: https://github.com/swagger-api/swagger-codegen.git

=end comment

=cut

#
# NOTE: This class is auto generated by the swagger code generator program. 
# Do not edit the class manually.
# Ref: https://github.com/swagger-api/swagger-codegen
#
__PACKAGE__->mk_classdata('attribute_map' => {});
__PACKAGE__->mk_classdata('swagger_types' => {});
__PACKAGE__->mk_classdata('method_documentation' => {}); 
__PACKAGE__->mk_classdata('class_documentation' => {});

# new object
sub new { 
    my ($class, %args) = @_; 

	my $self = bless {}, $class;
	
	foreach my $attribute (keys %{$class->attribute_map}) {
		my $args_key = $class->attribute_map->{$attribute};
		$self->$attribute( $args{ $args_key } );
	}
	
	return $self;
}  

# return perl hash
sub to_hash {
    return decode_json(JSON->new->convert_blessed->encode( shift ));
}

# used by JSON for serialization
sub TO_JSON { 
    my $self = shift;
    my $_data = {};
    foreach my $_key (keys %{$self->attribute_map}) {
        if (defined $self->{$_key}) {
            $_data->{$self->attribute_map->{$_key}} = $self->{$_key};
        }
    }
    return $_data;
}

# from Perl hashref
sub from_hash {
    my ($self, $hash) = @_;

    # loop through attributes and use swagger_types to deserialize the data
    while ( my ($_key, $_type) = each %{$self->swagger_types} ) {
    	my $_json_attribute = $self->attribute_map->{$_key}; 
        if ($_type =~ /^hash\[(.*),(.*)\]$/i) { #hash
            my ($key_type, $value_type) = ($1, $2);
            my %_hash = ();
            foreach my $_element (keys %{$hash->{$_json_attribute}}) {
                $_hash{$self->_deserialize($key_type, $_element)}
                    = $self->_deserialize($value_type, ${$hash->{$_json_attribute}}{$_element});
            }
            $self->{$_key} = \%_hash;
        } elsif ($_type =~ /^array\[/i) { # array
            my $_subclass = substr($_type, 6, -1);
            my @_array = ();
            foreach my $_element (@{$hash->{$_json_attribute}}) {
                push @_array, $self->_deserialize($_subclass, $_element);
            }
            $self->{$_key} = \@_array;
        } elsif (exists $hash->{$_json_attribute}) { #hash(model), primitive, datetime
            $self->{$_key} = $self->_deserialize($_type, $hash->{$_json_attribute});
        } else {
        	$log->debugf("Warning: %s (%s) does not exist in input hash\n", $_key, $_json_attribute);
        }
    }
  
    return $self;
}

sub _deserialize_date {
    my ($self, $data) = @_;
    my ($msec, $tz) = ($data =~ /^\/Date\((\d+)([+-]\d+)\)\/$/i);
    my $result = defined $msec ? DateTime->from_epoch(epoch => 0, time_zone => $tz)->add(seconds => int($msec)/1000)
        : DateTime->from_epoch(epoch => str2time($data));
    $log->debugf("   Value %s", $result);
    return $result;
}

# deserialize non-array data
sub _deserialize {
    my ($self, $type, $data) = @_;
    $log->debugf("deserializing %s with %s",Dumper($data), $type);
        
    if ($type eq 'DateTime') {
        return return $self->_deserialize_date($data);
    } elsif ( grep( /^$type$/, ('int', 'double', 'string', 'boolean'))) {
        return $data;
    } else { # hash(model)
        my $_instance = use_module("asposeomrcloud::Object::$type")->new();
        die "undefined data for type $type error $@"
            unless defined $_instance;
        return defined $data ? $_instance->from_hash($data) : $_instance;
    }
}



__PACKAGE__->class_documentation({description => 'The basic AsposeResponse response class kept from the old Aspose for Cloud Platform. We keep this base class and use it because most probably users are already using it to get API responses. The plan in future is to get rid of this name, but who knows when ?!',
                                  class => 'AsposeResponse',
                                  required => [], # TODO
}                                 );

__PACKAGE__->method_documentation({
    'status' => {
    	datatype => 'string',
    	base_name => 'Status',
    	description => 'Indicates operation&#39;s status',
    	format => '',
    	read_only => '',
    		},
});

__PACKAGE__->swagger_types( {
    'status' => 'string'
} );

__PACKAGE__->attribute_map( {
    'status' => 'Status'
} );

__PACKAGE__->mk_accessors(keys %{__PACKAGE__->attribute_map});


1;
