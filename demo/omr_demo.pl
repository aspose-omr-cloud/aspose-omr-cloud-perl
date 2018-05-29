BEGIN { $| = 1 }

use FindBin;
use lib qq{$FindBin::Bin/../lib};
#use lib 'lib';

use strict;
use warnings;
use asposeomrcloud::OmrApi;
use asposeomrcloud::Object::OMRFunctionParam;
use Data::Dumper;
use Log::Any::Adapter;
use File::Basename;
use MIME::Base64;
use File::Temp qw/ tempfile tempdir /;

#To enable debugging, uncomment following line
#use Log::Any::Adapter ('Stdout');


use AsposeStorageCloud::StorageApi;
use AsposeStorageCloud::ApiClient;
use AsposeStorageCloud::Configuration;
use AsposeStorageCloud::Object::FileExist;
use AsposeStorageCloud::Object::FileExistResponse;

# File with dictionary for configuration in JSON format
# The config file should look like:
# {
#     "app_key"  : "xxxxx",
#     "app_sid"   : "xxx-xxx-xxx-xxx-xxx",
#     "base_path" : "https://api.aspose.cloud/v1.1",
#     "data_folder" : "Data"
# }
# Provide your own app_key and app_sid, which you can receive by registering at Aspose Cloud Dashboard (https://dashboard.aspose.cloud/) 
my $CONFIG = 'test_config.json';
my $DEMO_DATA_SUBMODULE_NAME = 'aspose-omr-cloud-demo-data';

# Output path where all results are placed
my $PATH_TO_OUTPUT = './Temp';

# Name of the folder where all images used in template generation are located
my $LOGOS_FOLDER_NAME = 'Logos';

# Task file names
my $TEMPLATE_NAME = 'Aspose_test';
my $TEMPLATE_DST_NAME = $TEMPLATE_NAME . '.txt';
my @TEMPLATE_USER_IMAGES_NAMES = ('photo.jpg', 'scan.jpg');
my @TEMPLATE_LOGOS_IMAGES_NAMES = ('logo1.jpg', 'logo2.png');

# Instantiate a StorageApi object
# param config: JSON dictionary containing config data
# return: Configured StorageApi() object
package Storage;
sub new {
    my $type = shift;
    my $config = shift;

    $AsposeStorageCloud::Configuration::app_sid = $config->{app_sid};
    $AsposeStorageCloud::Configuration::api_key = $config->{app_key};
    $AsposeStorageCloud::Configuration::api_server = $config->{base_path};

    my $self = {
        api => AsposeStorageCloud::StorageApi->new()
    };
    return bless $self, $type;
}

# Upload files to the storage
# :param src_file: Source file path
# :param dst_path: Destination path
# :return: None
sub upload_file{
    my ( $self, $src_file, $dst_path ) = @_;
    my $response = $self->{api}->PutCreate(Path => $dst_path, file => $src_file);
    die "Cannot upload file $src_file" unless $response->{Status} eq 'OK';
    print("File $dst_path uploaded successfully with response $response->{'Status'}\n")
}

# Upload logo images used during template generation in a separate folder on cloud storage
# :data_dir_path: Path to directory containing logo images
# :return: None
sub upload_demo_files {
    my ( $self, $data_dir_path) = @_;
    my $response = $self->{api}->GetIsExist(Path => $LOGOS_FOLDER_NAME);
    if (not $response->{'FileExist'}->{'IsExist'}){
        $self->{api}->PutCreateFolder(Path => $LOGOS_FOLDER_NAME);
    }

    foreach my $file_name (@TEMPLATE_LOGOS_IMAGES_NAMES) {
        $self->upload_file(File::Spec->join($data_dir_path, $file_name), "$LOGOS_FOLDER_NAME/$file_name");
    }
}


package Demo;
sub new {
    my $type = shift;
    my $curr_path = File::Spec->rel2abs( File::Spec->curdir() );
    my $config_file_relative_path = File::Spec->join($DEMO_DATA_SUBMODULE_NAME, $CONFIG);
    while ($curr_path ne File::Spec->join($curr_path, '..') and not -e File::Spec->join($curr_path, $config_file_relative_path)){
        $curr_path = File::Spec->rel2abs(File::Spec->join($curr_path, '..'))
    }
    my $config_file_path = File::Spec->join($curr_path, $config_file_relative_path);
    my $config = undef;
    if (-e $config_file_path){
        my $config_content;
        {
            local $/;
            open my $fh, '<', $config_file_path or die "Can't open config file $config_file_path: $!";
            $config_content = <$fh>;
        }

        $config = JSON::decode_json($config_content);
    } else {
        die "Config file $CONFIG does not exist ";
    }
    die "app_sid not defined in $CONFIG" unless defined $config->{app_sid};
    die "app_key not defined in $CONFIG" unless defined $config->{app_key};
    die "base_path not defined in $CONFIG" unless defined $config->{base_path};
    die "data_folder not defined in $CONFIG" unless defined $config->{data_folder};

    my $self = {
        config => $config,
        data_folder => File::Spec->join(::dirname($config_file_path), $config->{data_folder}),
        storage => Storage->new($config),
        omr_api => asposeomrcloud::OmrApi->new($config->{app_key}, $config->{app_sid}, $config->{base_path})
    };
    return bless $self, $type;
}

# Deserialize single response file to the specified location
# :param file_info: Response file to deserialize
# :param dst_path: Destination folder path
# :return: Path to deserialized file
sub deserialize_file{
    my ($self, $file_info, $dst_path) = @_;
    if (not -e $dst_path){
        mkdir $dst_path;
    }
    my $dst_file_path = File::Spec->join($dst_path, $file_info->{name});
    my $decoded = ::decode_base64($file_info->{data});
    #print("Deserializing file $dst_file_path");
    open FILEHANDLE,">$dst_file_path" or die "Error opening file $dst_file_path: $!\n";
    binmode FILEHANDLE;
    print FILEHANDLE $decoded;
    close FILEHANDLE;
    return $dst_file_path;
}

# Deserialize list of files to the specified location
# :param files: List of response files
# :param dst_path: Destination folder path
# :return: Path to deserialized files
sub deserialize_files{
    my $self = shift;
    my $files_ref = shift;
    my $dst_path = shift;
    my @result = ();

    #my ($self, $files, $dst_path) = @_;
    foreach my $file (@{$files_ref}) {
        push @result, $self->deserialize_file($file, $dst_path);
    }
    return @result;
}

# Serialize files to JSON object
# :param file_paths: array of input file paths
# :return: JSON string with serialized files 
sub serialize_files{
    my $self = shift;
    my $files_ref = shift;
    my @files = ();
    foreach my $file_path (@{$files_ref}) {
        my $file_length = (stat $file_path)[7];

        open FILEHANDLE, $file_path or die "Error opening file $file_path: $!\n";
        binmode FILEHANDLE;
        my $buffer = undef;
        read FILEHANDLE, $buffer, $file_length, 0;
        close FILEHANDLE;

        push @files, { Name => ::basename($file_path)
                    , Size => $file_length
                    , Data => ::encode_base64($buffer)}

    }
    return JSON::to_json({Files => \@files});
}

# Generate new template based on provided text description
# :param omr_api: OMR API Instance
# :param template_file_path: Path to template text description
# :param logos_folder: Name of the cloud folder with logo images
# :return: Generation response
sub generate_template {
    my ($self, $template_file_path, $logos_folder) = @_;
    my $file_name = ::basename($template_file_path);
    $self->{storage}->upload_file($template_file_path, $file_name);

    my $response = $self->{omr_api}->post_run_omr_task(name => $file_name, action_name => "GenerateTemplate"
        , param => asposeomrcloud::Object::OMRFunctionParam->new(('FunctionParam' => JSON::to_json({ExtraStoragePath => $logos_folder})))
    );
    die "GenerateTemplate failed $response->{error_text}" unless $response->{error_code} == 0;
    #print(::Dumper($response));
    return $response;
}

# Run template correction
# :param omr_api: OMR API Instance
# :param template_image_path: Path to template image
# :param template_data_dir: Path to template data file (.omr)
# :return: Correction response
sub correct_template {
    my ($self, $template_image_path, $image_file_path) = @_;
    my $image_file_name = ::basename($image_file_path);
    $self->{storage}->upload_file($image_file_path, $image_file_name);
    my @files = ($template_image_path);
    my $response = $self->{omr_api}->post_run_omr_task(name => $image_file_name, action_name => "CorrectTemplate"
        , param => asposeomrcloud::Object::OMRFunctionParam->new(('FunctionParam' => $self->serialize_files(\@files)))
    );
    die "CorrectTemplate failed $response->{error_text}" unless $response->{error_code} == 0;
    #print(::Dumper($response));
    return $response;
}

# Run template finalization
# :param omr_api:  OMR API Instance
# :param template_id: Template id received after template correction
# :param corrected_template_path: Path to corrected template (.omrcr)
# :return: Finalization response
sub finalize_template {
    my ($self, $template_id, $corrected_template_file_path) = @_;
    my $corrected_template_file_name = ::basename($corrected_template_file_path);
    $self->{storage}->upload_file($corrected_template_file_path, $corrected_template_file_name);

    my $response = $self->{omr_api}->post_run_omr_task(name => $corrected_template_file_name, action_name => "FinalizeTemplate"
        , param => asposeomrcloud::Object::OMRFunctionParam->new(('FunctionParam' => $template_id))
    );
    die "FinalizeTemplate failed $response->{error_text}" unless $response->{error_code} == 0;
    #print(::Dumper($response));
    return $response;
}

# Runs mark recognition on image
# :param omr_api: OMR API Instance
# :param template_id: Template ID
# :param image_path: Path to the image
# :return: Recognition response
sub recognize_image {
    my ($self, $template_id, $image_path) = @_;
    my $image_file_name = ::basename($image_path);
    $self->{storage}->upload_file($image_path, $image_file_name);

    my $response = $self->{omr_api}->post_run_omr_task(name => $image_file_name, action_name => "RecognizeImage"
        , param => asposeomrcloud::Object::OMRFunctionParam->new(('FunctionParam' => $template_id))
    );
    die "RecognizeImage failed $response->{error_text}" unless $response->{error_code} == 0;
    #print(::Dumper($response));
    return $response;
}

# Helper function that combines correct_template and finalize_template calls
# :param omr_api: OMR API Instance
# :param template_image_path: Path to template image
# :param template_data_dir: The folder where Template Data will be stored
# :return: Template ID
sub validate_template {
    my ($self, $template_image_path, $image_file_path) = @_;
    my $corrected_template_file_path = undef;

    print("\t\tCorrect template...\n");
    my $response = $self->correct_template($template_image_path, $image_file_path);
    foreach my $file_path ($self->deserialize_files($response->{payload}->{result}->{response_files}, $PATH_TO_OUTPUT)) {
        if ($file_path =~ /.omrcr$/) { $corrected_template_file_path = $file_path }
    }
    my $template_id = $response->{payload}->{result}->{template_id};

    print("\t\tFinalize template...\n");
    return $self->finalize_template($template_id, $corrected_template_file_path);
}


sub demo {
    my $self = shift;
    print("Using $self->{config}->{base_path} as $self->{config}->{app_sid}\n");
    print("\t\tUploading demo files...\n");
    $self->{storage}->upload_demo_files($self->{data_folder});
# Step 1: Upload demo files on cloud and Generate template
    print("\t\tGenerate template...\n");
    my $response = $self->generate_template(File::Spec->join($self->{data_folder}, $TEMPLATE_DST_NAME), $LOGOS_FOLDER_NAME);
    my $template_file_path = undef;
    my $image_file_path = undef;

    foreach my $file_path ($self->deserialize_files($response->{payload}->{result}->{response_files}, $PATH_TO_OUTPUT)) {
        if ($file_path =~ /.omr$/) { $template_file_path = $file_path }
        if ($file_path =~ /.png$/) { $image_file_path = $file_path }
    }
# Step 2: Validate template
    $response = $self->validate_template($template_file_path, $image_file_path);
    $self->deserialize_files($response->{payload}->{result}->{response_files}, $PATH_TO_OUTPUT);
    my $template_id = $response->{payload}->{result}->{template_id};
# Step 3: Recognize photos and scans
    print("\t\tRecognize image...\n");
    my @output_files = ();
    foreach my $file_name (@TEMPLATE_USER_IMAGES_NAMES) {
        $response = $self->recognize_image($template_id, File::Spec->join($self->{data_folder}, $file_name));
        foreach my $file_path ($self->deserialize_files($response->{payload}->{result}->{response_files}, $PATH_TO_OUTPUT)) {
            if ($file_path =~ /.dat/) { push @output_files, $file_path }
        }
    }
    print("------ R E S U L T ------\n");
    foreach my $file_path (@output_files) {
        print("Output file $file_path\n");
    }
}




package main;
my $demo = Demo->new();
$demo->demo();
