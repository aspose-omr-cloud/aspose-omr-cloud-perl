# asposeomrcloud::Object::OmrResponseContent

## Load the model package
```perl
use asposeomrcloud::Object::OmrResponseContent;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**template_id** | **string** | GUID string that is used to identify template on server This value is assigned after Template Correction and used later in Template Finalization and Image Recognition | [optional] 
**execution_time** | **double** | Indicates how long it took to perform task on server. | 
**response_files** | [**ARRAY[FileInfo]**](FileInfo.md) | This structure holds array of files returned in response Type and content of files differes depending on action | [optional] 
**info** | [**OmrResponseInfo**](OmrResponseInfo.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


