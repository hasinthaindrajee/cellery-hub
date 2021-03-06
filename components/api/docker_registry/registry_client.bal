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

import ballerina/config;
import ballerina/http;

function getOAuth2RegistryClient(string bearerToken) returns http:Client {
    http:Client dockerRegistryClient = new(config:getAsString("docker.registry.url"), config = {
        auth: {
            scheme: http:OAUTH2,
            config: {
                grantType: http:DIRECT_TOKEN,
                config: {
                    accessToken: bearerToken
                }
            }            
        },
        secureSocket: {
            trustStore: {
                path: config:getAsString("security.truststore"),
                password: config:getAsString("security.truststorepass")
            },
            verifyHostname: false
        }
    });
    return dockerRegistryClient;
}
