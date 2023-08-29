import json
import os
import requests
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

import botocore.session
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from botocore.credentials import Credentials

# initialization: environment variables
region = os.environ.get("AWS_REGION", "us-east-1")
lattice_endpoint = os.environ.get("LATTICE_SERVICE_ENDPOINT", "undefined")

# initialization: boto
session = botocore.session.get_session()

# initialization: xray
patch_all()

# helper functions
def parse_flag(event, flag):
    response = False
    if flag in event and event[flag] == "true":
        response = True
    return response

def send_request(event, add_sigv4=False, debug=False):
    data = json.dumps(event)
    headers = {
        # "x-amz-content-sha256": "UNSIGNED-PAYLOAD",
        "content-type": "application/json"
        
    }
    url = f"https://{lattice_endpoint}"
    request = AWSRequest(method="POST", url=url, data=data, headers=headers)
    request.context["payload_signing_enabled"] = False

    if add_sigv4:
        print("adding sigv4 auth to the request") if debug else None
        sigv4 = SigV4Auth(session.get_credentials(), "vpc-lattice-svcs", region)
        sigv4.add_auth(request)

    print(f"sending request to {url}") if debug else None
    prepped = request.prepare()
    response = requests.post(prepped.url, headers=prepped.headers, data=data, timeout=10)

    # response is of type requests.models.Response
    if response.status_code == 200:
        output = response.json()
    else:
        output = {
            "status_code": response.status_code,
            "reason": response.reason
        }
    return output

def handler(event, context):
    print(json.dumps(event))
    enable_sigv4 = parse_flag(event, "sigv4")
    enable_debug = parse_flag(event, "debug")
    output = send_request(event, add_sigv4=enable_sigv4, debug=enable_debug)
    print(json.dumps(output))
    return output
