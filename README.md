# Inferno SMART App Launch Test Kit

This is a collection of tests for the [SMART Application Launch Framework
Implementation Guide](http://hl7.org/fhir/smart-app-launch/index.html) using the
[Inferno Framework](https://inferno-framework.github.io/inferno-core/), verifying
that a server can provide authorization and/or authentication services to client 
applications accessing HL7® FHIR® APIs.

## Instructions

- Clone this repo.
- Run `setup.sh` in this repo.
- Run `run.sh` in this repo.
- Navigate to `http://localhost`. The SMART test suite will be available.

## Versions
This test kit contains both the SMART App Launch STU1 and SMART App Launch STU2
suites. While these suites are generally designed to test implementations of
the SMART App Launch Framework, each suite is tailored to the
[STU1](https://hl7.org/fhir/smart-app-launch/1.0.0/) and
[STU2](http://hl7.org/fhir/smart-app-launch/STU2/) versions of SMART, respectively.

## Importing tests

Tests from this test kit can be imported to perform the SMART App Launch
workflow as part of another test suite. The tests are arranged in groups which
can be easily reused.

In order for the redirect and launch urls to be determined correctly, make sure
that the `INFERNO_HOST` environment variable is populated in `.env` with the
scheme and host where inferno will be hosted.

### Example

```ruby
require 'smart_app_launch_test_kit'

class MySuite < Inferno::TestSuite
  input :url

  group do
    title 'Auth'

    group from: :smart_discovery
    group from: :smart_standalone_launch
    group from: :smart_openid_connect
  end

  group do
    title 'Make some HL7® FHIR® requests using SMART credentials'

    input :smart_credentials

    fhir_client do
      url :url
      oauth_credentials :smart_credentials # Obtained from the auth group
    end

    test do
      title 'Retrieve patient from SMART launch context'

      input :patient_id

      run do
        fhir_read(:patient, patient_id)

        assert_response_status(200)
        assert_resource_type(:patient)
      end
    end
  end
end
```

### Discovery Group

The Discovery Group ([STU1](https://github.com/inferno-framework/smart-app-launch-test-kit/blob/main/lib/smart_app_launch/discovery_stu1_group.rb)
and [STU2](https://github.com/inferno-framework/smart-app-launch-test-kit/blob/main/lib/smart_app_launch/discovery_stu2_group.rb))
examines a server's CapabilityStatement and `.well-known/smart-configuration`
endpoint to determine its configuration.

**ids:** `smart_discovery`, `smart_discovery_stu2`

**inputs:** `url`

**outputs:**
* `well_known_configuration` - The contents of `.well-known/smart-configuration`
* `smart_authorization_url`
* `smart_introspection_url`
* `smart_management_url`
* `smart_registration_url`
* `smart_revocation_url`
* `smart_token_url`

### Standalone Launch Group

The Standalone Launch Group ([STU1](https://github.com/inferno-framework/smart-app-launch-test-kit/blob/main/lib/smart_app_launch/standalone_launch_group.rb)
and [STU2](https://github.com/inferno-framework/smart-app-launch-test-kit/blob/main/lib/smart_app_launch/standalone_launch_group_stu2.rb))
performs the entire standalone launch workflow.

**ids:** `smart_standalone_launch`, `smart_standalone_launch_stu2`

**inputs:** `url`, `client_id`, `client_secret`, `requested_scopes`

**outputs:**
* `smart_credentials` - An [OAuthCredentials
  Object](https://inferno-framework.github.io/inferno-core/docs/Inferno/DSL/OAuthCredentials.html)
  containing the credentials obtained from the launch.
* `token_retrieval_time`
* `id_token`
* `refresh_token`
* `access_token`
* `expires_in`
* `patient_id`
* `encounter_id`
* `received_scopes`
* `intent`

**options:**
* `redirect_uri`: You should not have to manually set this if the `INFERNO_HOST`
  environment variable is set.
* `ignore_missing_scopes_check`: Forego checking that the scopes granted by the
 token match those requested.

### EHR Launch Group

The EHR Launch Group ([STU1](https://github.com/inferno-framework/smart-app-launch-test-kit/blob/main/lib/smart_app_launch/ehr_launch_group.rb)
and [STU2](https://github.com/inferno-framework/smart-app-launch-test-kit/blob/main/lib/smart_app_launch/ehr_launch_group_stu2.rb))
performs the entire EHR launch workflow.

**ids:** `smart_ehr_launch`, `smart_ehr_launch_stu2`

**inputs:** `url`, `client_id`, `client_secret`, `requested_scopes`

**outputs:**
* `smart_credentials` - An [OAuthCredentials
  Object](https://inferno-framework.github.io/inferno-core/docs/Inferno/DSL/OAuthCredentials.html)
  containing the credentials obtained from the launch.
* `token_retrieval_time`
* `id_token`
* `refresh_token`
* `access_token`
* `expires_in`
* `patient_id`
* `encounter_id`
* `received_scopes`
* `intent`

**options:**
* `launch`: a hardcoded value to use instead of the `launch` parameter received
  during the launch
* `redirect_uri`: You should not have to manually set this if the `INFERNO_HOST`
  environment variable is set.
* `launch_uri`: You should not have to manually set this if the `INFERNO_HOST`
  environment variable is set.
* `ignore_missing_scopes_check`: Forego checking that the scopes granted by the
 token match those requested.

### OpenID Connect Group
[The OpenID Connect
Group](https://github.com/inferno-framework/smart-app-launch-test-kit/blob/main/lib/smart_app_launch/openid_connect_group.rb)
validates an id token obtained during a SMART launch.

**id:** `smart_openid_connect`

**inputs:** `id_token`, `client_id`, `requested_scopes`, `access_token`,
`smart_credentials`

**outputs:**
* `id_token_payload_json`
* `id_token_header_json`
* `openid_configuration_json`
* `openid_issuer`
* `openid_jwks_uri`
* `openid_jwks_json`
* `openid_rsa_keys_json`
* `id_token_jwk_json`
* `id_token_fhir_user`

### Token Refresh Group

[The Token Refresh
Group](https://github.com/inferno-framework/smart-app-launch-test-kit/blob/main/lib/smart_app_launch/token_refresh_group.rb)
performs a token refresh.

**id:** `smart_token_refresh`

**inputs:** `refresh_token`, `client_id`, `client_secret`, `received_scopes`,
`well_known_token_url`

**outputs:**
* `smart_credentials` - An [OAuthCredentials
  Object](https://inferno-framework.github.io/inferno-core/docs/Inferno/DSL/OAuthCredentials.html)
  containing the credentials obtained from the launch.
* `token_retrieval_time`
* `refresh_token`
* `access_token`
* `expires_in`
* `received_scopes`

**options:**
* `include_scopes`: (`true/false`) Whether to include scopes in the refresh
  request


## License

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at
```
http://www.apache.org/licenses/LICENSE-2.0
```
Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.


### Aidbox Inferno Test
#### STU1
##### 1. 上傳測試用的病人資料到 Aidbox，這些資料由 Health Samurai 團隊維護，存放在 Google Storage。
![alt text](/images/image1.png)
```
POST /$load
content-type: application/json
accept: application/json

{
  "source": "https://storage.googleapis.com/aidbox-public/smartbox/rows.ndjson.gz"
}
```
##### 2. 創建一個測試用的使用者 (test-user)，並將其與一個 Patient 資源 (test-pt-1) 相關聯。這個使用者可以用來登入 Aidbox。
![alt text](/images/image2.png)
```
PUT /User/test-user
content-type: application/json
accept: application/json

{
  "email": "example@mail.com",
  "password": "password",
  "name": {
    "givenName": "Amy",
    "familyName": "Shaw"
  },
  "active": true,
  "fhirUser": {
    "id": "test-pt-1",
    "resourceType": "Patient"
  },
  "id": "test-user"
}
```
##### 3. 建立一個 Client 資源( 只是 Aidbox 內的 Client 配置，並不會實際創建 APP)，這是用來模擬執行 SMART on FHIR 驗證流程的應用程式（類似 OAuth 客戶端）。它支援 authorization_code 授權類型，啟用了 PKCE，並設定了 Redict URL。注意: grant_types 有設定 authorization_cod 和 basic，代表可以支援 授權碼 換取 access_token 的 OAuth2 授權碼流程，又或是 client id 和 secret Base64 編碼後，用 Authorization header 的值固定。
![alt text](images/image3.png)
```
PUT /
content-type: application/json
accept: application/json

[
  {
    "id": "inferno-patient-smart-app",
    "resourceType": "Client",
    "type": "smart-app",
    "active": true,
    "grant_types": [
      "authorization_code",
      "basic"
    ],
    "auth": {
      "authorization_code": {
        "pkce": true,
        "redirect_uri": "https://192.168.1.16/custom/smart/redirect",
        "refresh_token": true,
        "token_format": "jwt",
        "access_token_expiration": 300
      }
    },
    "scope": ["launch/patient", "openid", "fhirUser", "offline_access", "patient/*.read"],
    "smart": {
      "launch_uri": "https://192.168.1.16/custom/smart/launch"
    },
    "secret": "verysecret"
  },
  {
    "id": "inferno-client-allow",
    "link": [
      {
        "id": "inferno-patient-smart-app",
        "resourceType": "Client"
      }
    ],
    "engine": "allow",
    "resourceType": "AccessPolicy"
  }
]
```

#### STU2
##### 1. 上傳測試用的病人資料到 Aidbox，這些資料由 Health Samurai 團隊維護，存放在 Google Storage。
```
POST /$load
content-type: application/json
accept: application/json

{
  "source": "https://storage.googleapis.com/aidbox-public/smartbox/rows.ndjson.gz"
}
```
##### 2. 創建一個測試用的使用者 (test-user)，並將其與一個 Patient 資源 (test-pt-1) 相關聯。這個使用者可以用來登入 Aidbox。
```
PUT /User/test-user
content-type: application/json
accept: application/json

{
  "email": "example@mail.com",
  "password": "password",
  "name": {
    "givenName": "Amy",
    "familyName": "Shaw"
  },
  "active": true,
  "fhirUser": {
    "id": "test-pt-1",
    "resourceType": "Patient"
  },
  "id": "test-user"
}
```
##### 3. 建立一個 Client 資源( 只是 Aidbox 內的 Client 配置，並不會實際創建 APP)，這是用來模擬執行 SMART on FHIR 驗證流程的應用程式（類似 OAuth 客戶端）。它支援 authorization_code 授權類型，啟用了 PKCE，並設定了 Redict URL。注意: grant_types 有設定 authorization_cod 和 basic，代表可以支援 授權碼 換取 access_token 的 OAuth2 授權碼流程，又或是 client id 和 secret Base64 編碼後，用 Authorization header 的值固定。
```
PUT /
content-type: application/json
accept: application/json

[
  {
    "id": "inferno-patient-smart-app",
    "resourceType": "Client",
    "type": "smart-app",
    "active": true,
    "grant_types": [
      "authorization_code",
      "basic"
    ],
    "auth": {
      "authorization_code": {
        "pkce": true,
        "redirect_uri": "https://192.168.1.16/custom/smart_stu2/redirect",
        "refresh_token": true,
        "token_format": "jwt",
        "access_token_expiration": 300
      }
    },
    "scope": ["launch/patient", "openid", "fhirUser", "offline_access", "patient/*.read"],
    "smart": {
      "launch_uri": "https://192.168.1.16/custom/smart_stu2/launch"
    },
    "secret": "verysecret"
  },
  {
    "id": "inferno-client-allow",
    "link": [
      {
        "id": "inferno-patient-smart-app",
        "resourceType": "Client"
      }
    ],
    "engine": "allow",
    "resourceType": "AccessPolicy"
  }
]
```

#### STU2.2
##### 1. 上傳測試用的病人資料到 Aidbox，這些資料由 Health Samurai 團隊維護，存放在 Google Storage。
```
POST /$load
content-type: application/json
accept: application/json

{
  "source": "https://storage.googleapis.com/aidbox-public/smartbox/rows.ndjson.gz"
}
```
##### 2. 創建一個測試用的使用者 (test-user)，並將其與一個 Patient 資源 (test-pt-1) 相關聯。這個使用者可以用來登入 Aidbox。
```
PUT /User/test-user
content-type: application/json
accept: application/json

{
  "email": "example@mail.com",
  "password": "password",
  "name": {
    "givenName": "Amy",
    "familyName": "Shaw"
  },
  "active": true,
  "fhirUser": {
    "id": "test-pt-1",
    "resourceType": "Patient"
  },
  "id": "test-user"
}
```
##### 3. 建立一個 Client 資源( 只是 Aidbox 內的 Client 配置，並不會實際創建 APP)，這是用來模擬執行 SMART on FHIR 驗證流程的應用程式（類似 OAuth 客戶端）。它支援 authorization_code 授權類型，啟用了 PKCE，並設定了 Redict URL。注意: grant_types 有設定 authorization_cod 和 basic，代表可以支援 授權碼 換取 access_token 的 OAuth2 授權碼流程，又或是 client id 和 secret Base64 編碼後，用 Authorization header 的值固定。
```
PUT /
content-type: application/json
accept: application/json

[
  {
    "id": "inferno-patient-smart-app",
    "resourceType": "Client",
    "type": "smart-app",
    "active": true,
    "grant_types": [
      "authorization_code",
      "basic"
    ],
    "auth": {
      "authorization_code": {
        "pkce": true,
        "redirect_uri": "https://192.168.1.16/custom/smart_stu2_2/redirect",
        "refresh_token": true,
        "token_format": "jwt",
        "access_token_expiration": 300
      }
    },
    "scope": ["launch/patient", "openid", "fhirUser", "offline_access", "patient/*.read"],
    "smart": {
      "launch_uri": "https://192.168.1.16/custom/smart_stu2_2/launch"
    },
    "secret": "verysecret"
  },
  {
    "id": "inferno-client-allow",
    "link": [
      {
        "id": "inferno-patient-smart-app",
        "resourceType": "Client"
      }
    ],
    "engine": "allow",
    "resourceType": "AccessPolicy"
  }
]
```

#### GET EHR Launch URL，注意: 並不會真正創建 EHR App，只是 模擬 一個 EHR 啟動場景
![alt text](/images/image4.png)
```
POST /rpc
content-type: application/json
accept: application/json
authorization: Basic aW5mZXJuby1wYXRpZW50LXNtYXJ0LWFwcDp2ZXJ5c2VjcmV0

{
  "method": "aidbox.smart/get-launch-uri",
  "params": {
    "user": "test-user",
    "iss": "http://192.168.1.16:8080/fhir",
    "client": "inferno-patient-smart-app",
    "ctx": {
      "patient": "test-pt-1"
    }
  }
}
```
#### Inferno Input
```
FHIR Endpoint: http://192.168.1.16:8080/fhir

Standalone Client ID: inferno-patient-smart-app

Standalone Client Secret: verysecret

EHR Launch Client ID: inferno-patient-smart-app

EHR Launch Client Secret: verysecret
```
