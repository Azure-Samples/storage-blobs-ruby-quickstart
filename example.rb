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
# Associated Article - https://docs.microsoft.com/azure/storage/blobs/storage-quickstart-blobs-ruby
# What is a Storage Account - https://docs.microsoft.com/azure/storage/common/storage-create-storage-account
# Getting Started with Blobs-https://docs.microsoft.com/azure/storage/blobs/storage-ruby-how-to-use-blob-storage
# Blob Service Concepts - https://docs.microsoft.com/rest/api/storageservices/Blob-Service-Concepts
# Blob Service REST API - https://docs.microsoft.com/rest/api/storageservices/Blob-Service-REST-API
# ----------------------------------------------------------------------------------------------------------

require "openssl"
require "securerandom"
require "rbconfig"

# Require the azure storage blob rubygem
require "azure/storage/blob"

$stdout.sync = true

# This sample application creates a container in an Azure Blob Storage account,
# uploads data to the container, lists the blobs in the container, and downloads a blob to a local file.
def run_sample
    is_windows = (RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/)

    # Create a BlobService object
    blob_client = Azure::Storage::Blob::BlobService 

    begin

        # Create a BlobService object
        account_name = "accountname"
        account_key = "accountkey"

            blob_client = Azure::Storage::Blob::BlobService.create(
            storage_account_name: account_name,
            storage_access_key: account_key
        )

        # Create a container
        container_name = "quickstartblobs" + SecureRandom.uuid
        puts "\nCreating a container: " + container_name
        container = blob_client.create_container(container_name)
        
        # Set the permission so the blobs are public
        blob_client.set_container_acl(container_name, "container")

        # Create a new block blob containing 'Hello, World!'
        blob_name = "QuickStart_" + SecureRandom.uuid + ".txt"
        blob_data = "Hello, World!"
        puts "\nCreating blob: " + blob_name
        blob_client.create_block_blob(container.name, blob_name, blob_data)

        # List the blobs in the container
        puts "\nList blobs in the container following continuation token"
        nextMarker = nil
        loop do
            blobs = blob_client.list_blobs(container_name, { marker: nextMarker })
            blobs.each do |blob|
                puts "\tBlob name: #{blob.name}"
            end
            nextMarker = blobs.continuation_token
            break unless nextMarker && !nextMarker.empty?
        end

        # Download the blob

        # Set the path to the local folder for downloading
        if(is_windows)
            local_path = File.expand_path("~/Documents")
        else 
            local_path = File.expand_path("~/")
        end

        # Create the full path to the downloaded file
        full_path_to_file = File.join(local_path, blob_name)

        puts "\nDownloading blob to " + full_path_to_file
        blob, content = blob_client.get_blob(container_name, blob_name)
        File.open(full_path_to_file,"wb") {|f| f.write(content)}

        puts "\nPaused, press the Enter key to delete resources created by the sample and exit the application "
        readline()

    rescue Exception => e
        puts e.message
    ensure
        # Clean up resources, including the container and the downloaded file
        blob_client.delete_container(container_name)
        File.delete(full_path_to_file)
    end
end

# Main method
run_sample
