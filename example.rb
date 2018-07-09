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
require 'rbconfig'

# Require the azure storage blob rubygem
require 'azure/storage/blob'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
$stdout.sync = true


# Method that creates a test file in the 'Documents' folder or in the home directory on Linux.
# This sample application creates a test file, uploads the test file to the Blob storage,
# lists the blobs in the container, and downloads the file with a new name.
def run_sample
    account_name = 'accountname'   
    account_key = 'accountkey'
    is_windows = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)

    # Create a BlobService object
    blob_client = Azure::Storage::Blob::BlobService 

    begin

        # Create a BlobService object
        blob_client = Azure::Storage::Blob::BlobService.create(
            storage_account_name: account_name,
            storage_access_key: account_key
        )

        # Create a container called 'quickstartblobs'.
        container_name = 'quickstartblobs' + SecureRandom.uuid
        puts "Creating a container: " + container_name
        container = blob_client.create_container(container_name)   
        
        # Set the permission so the blobs are public.
        blob_client.set_container_acl(container_name, "container")

        # Create a file in Documents to test the upload and download.
        if(is_windows)
            local_path = File.expand_path("~/Documents")
        else 
            local_path = File.expand_path("~/")
        end

        local_file_name = "QuickStart_" + SecureRandom.uuid + ".txt"
        full_path_to_file = File.join(local_path, local_file_name)

        # Write text to the file.
        file = File.open(full_path_to_file,  'w')
        file.write("Hello, World!")
        file.close()
   
        puts "\nCreated a temp file: " + full_path_to_file
        puts "\nUploading to Blob storage as blob: " + local_file_name

        # Upload the created file using local_file_name for the blob name
        blob_client.create_block_blob(container.name, local_file_name, IO.binread(full_path_to_file))

        # List the blobs in the container
        puts "\nList blobs in the container following continuation token"
        nextMarker = nil
        loop do
            blobs = blob_client.list_blobs(container_name, { marker: nextMarker })
            blobs.each do |blob|
                puts "\tBlob name #{blob.name}"
            end
            nextMarker = blobs.continuation_token
            break unless nextMarker && !nextMarker.empty?
        end
        
        # Download the blob(s).
        # Add '_DOWNLOADED' as prefix to '.txt' so you can see both files in Documents.
        full_path_to_file2 = File.join(local_path, local_file_name.gsub('.txt', '_DOWNLOADED.txt'))
        
        puts "\nDownloading blob to " + full_path_to_file2
        blob, content = blob_client.get_blob(container_name,local_file_name)
        File.open(full_path_to_file2,"wb") {|f| f.write(content)}

        puts "Sample finished running. Hit <any key>, to delete resources created by the sample and exit the application"
        readline()

    rescue Exception => e
        puts e.message
    ensure
        # Clean up resources. This includes the container and the temp files
        blob_client.delete_container(container_name)
        File.delete(full_path_to_file)
        File.delete(full_path_to_file2)
    end
end   

# Main method.
run_sample
