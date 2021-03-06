// ------------------------------------------------------------------------
//
// Copyright 2019 WSO2, Inc. (http://wso2.com)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License
//
// ------------------------------------------------------------------------

import ballerina/filepath;
import ballerina/internal;
import ballerina/io;
import ballerina/log;
import ballerina/transactions;

public type CellImageMetadata record {
	string org;
	string name;
	string ver;
	string schemaVersion;
	string kind;
	map<ComponentMetadata> components;
	int buildTimestamp;
	string buildCelleryVersion;
	boolean zeroScalingRequired;
	boolean autoScalingRequired;
};

public type ComponentMetadata record {
	string dockerImage;
	boolean isDockerPushRequired;
	map<string> labels;
	string[] ingressTypes;
	ComponentDependencies dependencies;
};

public type ComponentDependencies record {
	map<CellImageMetadata> cells;
	map<CellImageMetadata> composites;
	string[] components;
};

const string IMAGE_KIND_CELL = "Cell";
const string IMAGE_KIND_COMPOSITE = "Composite";
string[] IMAGE_KINDS = [IMAGE_KIND_CELL, IMAGE_KIND_COMPOSITE];

const string INGRESS_TYPE_TCP = "TCP";
const string INGRESS_TYPE_HTTP = "HTTP";
const string INGRESS_TYPE_GRPC = "GRPC";
const string INGRESS_TYPE_WEB = "WEB";
string[] INGRESS_TYPES = [INGRESS_TYPE_TCP, INGRESS_TYPE_HTTP, INGRESS_TYPE_GRPC, INGRESS_TYPE_WEB];

# Extract the metadata for the cell iamge file layer.
#
# + cellImageBytes - Cell Image Zip bytes
# + return - metadata or an error
public function extractMetadataFromImage(byte[] cellImageBytes) returns (CellImageMetadata|error) {
    var transactionId = transactions:getCurrentTransactionId();
    var extractedCellImageDir = filepath:build("/", "tmp", "cell-image-" + transactionId);

    if (extractedCellImageDir is error) {
        error err = error("failed to resolve extract location due to " + extractedCellImageDir.reason());
        return err;
    } else {
        // Uncompressing the received Cell Image Bytes
        internal:Path zipDest = new(extractedCellImageDir);
        var zipDestDirCreateResult = zipDest.createDirectory();
        if (zipDestDirCreateResult is error) {
            error err = error("failed to create temp directory due to " + zipDestDirCreateResult.reason());
            return err;
        }
        var decompressResult = internal:decompressFromByteArray(cellImageBytes, zipDest);
        log:printDebug(io:sprintf("Extracted Cell image at %s for transaction %s", extractedCellImageDir,
            transactionId));

        if (decompressResult is error) {
            error err = error("failed to extract Cell Image due to " + decompressResult.reason());
            return err;
        } else {
            // Reading the metadata from the extracted Cell Image
            var cellImageMetadataFile = filepath:build(extractedCellImageDir, "artifacts", "cellery", "metadata.json");
            if (cellImageMetadataFile is string) {
                io:ReadableByteChannel metadataRbc = io:openReadableFile(untaint cellImageMetadataFile);
                io:ReadableCharacterChannel metadataRch = new(metadataRbc, "UTF8");
                var parsedMetadata = metadataRch.readJson();
                log:printDebug("Read Cell image metadata for transaction " + transactionId);

                if (parsedMetadata is json) {
                    var extracedCellImageDeleteResult = zipDest.delete();
                    if (extracedCellImageDeleteResult is error) {
                        log:printError(
                            io:sprintf("Failed to cleanup Cell Image extracted in directory %s for transaction %s",
                                extractedCellImageDir, transactionId),
                            err = extracedCellImageDeleteResult
                        );
                    } else {
                        log:printDebug("Cleaned up extracted Cell Image for transaction " + transactionId);
                    }
                    var cellImageMetadata = CellImageMetadata.convert(parsedMetadata);
                    if (cellImageMetadata is error) {
                        var stringConvertedMetadata = string.convert(parsedMetadata);
                        string metadataPayloadMessage;
                        if (stringConvertedMetadata is string) {
                            metadataPayloadMessage = " with metadata: " + stringConvertedMetadata;
                        } else {
                            metadataPayloadMessage = "";
                        }

                        var isForeignFormat = true;
                        if (parsedMetadata["buildCelleryVersion"] != ()) {
                            var buildCelleryVersion = string.convert(parsedMetadata["buildCelleryVersion"]);
                            var schemaVersion = string.convert(parsedMetadata["schemaVersion"]);
                            if (buildCelleryVersion is string && schemaVersion is string) {
                                log:printError("Format of the received metadata of Schema Version "
                                    + schemaVersion +  " built using Cellery "
                                    + buildCelleryVersion + " does not match Cellery Hub supported metadata "
                                    + "format for transaction " + transactionId + metadataPayloadMessage);
                                isForeignFormat = false;
                            }
                        }
                        if (isForeignFormat) {
                            log:printDebug("Format of the received metadata does not match Cellery Hub "
                                + "supported metadata format for transaction " + transactionId
                                + metadataPayloadMessage);
                        }
                        return cellImageMetadata;
                    } else {
                        var validationResult = validateMetadata(cellImageMetadata);
                        if (validationResult is error) {
                            log:printError("Invalid metadata format", err = validationResult);
                            return validationResult;
                        } else {
                            return cellImageMetadata;
                        }
                    }
                } else {
                    error err = error("failed to parse metadata.json due to " + parsedMetadata.reason());
                    var extracedCellImageDeleteResult = zipDest.delete();
                    if (extracedCellImageDeleteResult is error) {
                        log:printError(
                            io:sprintf("Failed to cleanup Cell Image extracted in directory %s for transaction %s",
                                extractedCellImageDir, transactionId),
                            err = extracedCellImageDeleteResult
                        );
                    } else {
                        log:printDebug("Cleaned up extracted Cell Image for transaction " + transactionId);
                    }
                    return err;
                }
            } else {
                error err = error("failed to resolve metadata.json file due to " + cellImageMetadataFile.reason());
                var extracedCellImageDeleteResult = zipDest.delete();
                if (extracedCellImageDeleteResult is error) {
                    log:printError(
                        io:sprintf("Failed to cleanup Cell Image extracted in directory %s for transaction %s",
                            extractedCellImageDir, transactionId),
                        err = extracedCellImageDeleteResult
                    );
                } else {
                    log:printDebug("Cleaned up extracted Cell Image for transaction " + transactionId);
                }
                return err;
            }
        }
    }
}

# Validate the metadata values and return error if invalid.
#
# + cellImageMetadata - cellImageMetadata Metadata to be validated
# + return - Error if invalid
function validateMetadata(CellImageMetadata cellImageMetadata) returns error? {
    // TODO: Update this validation to a ballerina enum based validation after migrating to Ballerina 1.0.0
    if (!isValidEnum(cellImageMetadata.kind, IMAGE_KINDS)) {
        error err = error(io:sprintf("invalid kind \"%s\" found", cellImageMetadata.kind));
        return err;
    }

    foreach var (componentName, component) in cellImageMetadata.components {
        foreach var ingressType in component.ingressTypes {
            if (!isValidEnum(ingressType, INGRESS_TYPES)) {
                error err = error(io:sprintf("invalid ingress type \"%s\" found", ingressType));
                return err;
            }
        }
    }
}

# Validate a enum value using an array of valid values.
#
# + actualValue - actualValue The actual value which should match the array of values
# + validValues - validValues The array of valid values for the enum value
# + return - Return Value Description
function isValidEnum(string actualValue, string[] validValues) returns boolean {
    var isValid = false;
    foreach var validValue in validValues {
        if (validValue == actualValue) {
            isValid = true;
            break;
        }
    }
    return isValid;
}
