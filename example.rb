# ----------------------------------------------------------------------------------
# MIT License
#
# Copyright(c) Microsoft Corporation. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# ----------------------------------------------------------------------------------
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# ---------------------------------------------------------------------------------------------------------
# Documentation References:
# Associated Article - https://docs.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-ruby
# What is a Storage Account - https://docs.microsoft.com/en-us/azure/storage/common/storage-create-storage-account
# Getting Started with Blobs-https://docs.microsoft.com/en-us/azure/storage/blobs/storage-ruby-how-to-use-blob-storage
# Blob Service Concepts - https://docs.microsoft.com/en-us/rest/api/storageservices/Blob-Service-Concepts
# Blob Service REST API - https://docs.microsoft.com/en-us/rest/api/storageservices/Blob-Service-REST-API
# ----------------------------------------------------------------------------------------------------------

require 'openssl'
require 'securerandom'

# Require the azure storage rubygem
require 'azure/storage'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
$stdout.sync = true


# Method that creates a test file in the 'Documents' folder.
# This sample application creates a test file, uploads the test file to the Blob storage,
# lists the blobs in the container, and downloads the file with a new name.
def run_sample
    account_name = 'accountname'   
    account_key = 'accountkey'
    
    begin

        # Setup a specific instance of an Azure::Storage::Client
        client = Azure::Storage.client(
            storage_account_name: account_name,
            storage_access_key: account_key
          )

        # Create the BlobService that is used to call the Blob service for the storage account
        blob_service = client.blob_client
        
        # Create a container called 'quickstartblobs'.
        container_name = 'quickstartblobs'
        container = blob_service.create_container(container_name)   
        
        # Set the permission so the blobs are public.
        blob_service.set_container_acl(container_name, "container")

        # Create a file in Documents to test the upload and download.
        local_path = File.expand_path("~/Documents")
        local_file_name = "QuickStart_" + SecureRandom.uuid + ".txt"
        full_path_to_file = File.join(local_path, local_file_name)

        # Write text to the file.
        file = File.open(full_path_to_file,  'w')
        file.write("Hello, World!")
        file.close()
   
        puts "Temp file = " + full_path_to_file
        puts "\nUploading to Blob storage as blob" + local_file_name

        # Upload the created file, use local_file_name for the blob name
        blob_service.create_block_blob(container.name, local_file_name, full_path_to_file)

        # List the blobs in the container
        puts "\n List blobs in the container"
        blobs = blob_service.list_blobs(container_name)
        blobs.each do |blob|
            puts "\t Blob name #{blob.name}"   
        end  
        
        # Download the blob(s).
        # Add '_DOWNLOADED' as prefix to '.txt' so you can see both files in Documents.
        full_path_to_file2 = File.join(local_path, local_file_name.gsub('.txt', '_DOWNLOADED.txt'))
        
        puts "\n Downloading blob to " + full_path_to_file2
        blob, content = blob_service.get_blob(container_name,local_file_name)
        File.open(full_path_to_file2,"wb") {|f| f.write(content)}

        puts "Sample finished running. Hit <any key>, to delete resources created by the sample and exit the application"
        readline()

        # Clean up resources. This includes the container and the temp files
        blob_service.delete_container(container_name)
        File.delete(full_path_to_file)
        File.delete(full_path_to_file2)    
    rescue Exception => e
        puts e.message
    end
end   

# Main method.
run_sample