# AWS VPN Demo 

You can demonstrate the feature of VPN Connection from onpremise network to VPC on AWS.

- Demo1: AWS Client VPN authenticated with AWS SSO
- (***Work in process***)Demo2: AWS Site-to-Site VPN

# Demo1: AWS Client VPC authenticated with AWS SSO

![demo1-aws-client-vpc](./images/Client-VPN-Demo.png)

[This image created by lucid chart](https://lucid.app/lucidchart/invitations/accept/inv_09bd1e41-9c85-4f11-89bd-99bd1a028714?view_items=SkpcrWSvMDYQ%2CSkpcL0ALpZH1%2CRupcZK0qZsse%2CXtpcL24kwHfa%2CAupcPyusYpcS%2CUypcnsH5SAgv%2CSkpckB-e_dvM%2CSkpcqOsgqnbv%2CGvpcD-dOSxFO%2CovpcKnMWmutN%2CSkpc1PTlG5qO%2CCApc~VCwzivK%2CFApc3~t33TIR)

This demo is based on the following blog content.

[Authenticate AWS Client VPN users with AWS Single Sign-On](https://aws.amazon.com/jp/blogs/security/authenticate-aws-client-vpn-users-with-aws-single-sign-on/)

***Note***: The Client VPC Endpoint created in this demo will be set as "Split-tunnel" enabled. Therefore, only the specific private IPs (172.16.0.0/16 or 10.0.0.0/8) will communicate through the Client VPN, and other communications will not be affected. If you are an AWS instructor and are delivering online, you can do this demo without affecting your delivery.


## Prerequisites

- AWS SSO is configured to use the internal AWS SSO identity store.
- Some AWS SSO users for testing.
- Create the VPN client SAML application in AWS SSO
  - see "To create the VPN client SAML application:
" section for detail: [Authenticate AWS Client VPN users with AWS Single Sign-On](https://aws.amazon.com/jp/blogs/security/authenticate-aws-client-vpn-users-with-aws-single-sign-on/)
- Create the VPN client self-service SAML application
  - see "To create the VPN client self-service SAML application" section for detail: [Authenticate AWS Client VPN users with AWS Single Sign-On](https://aws.amazon.com/jp/blogs/security/authenticate-aws-client-vpn-users-with-aws-single-sign-on/)
- Integrate the Client VPN SAML applications with IAM
  - see "Integrate the Client VPN SAML applications with IAM
" section for detail: [Authenticate AWS Client VPN users with AWS Single Sign-On](https://aws.amazon.com/jp/blogs/security/authenticate-aws-client-vpn-users-with-aws-single-sign-on/)
- A client device running Windows or macOS with the latest version of Client VPN software installed. You can download it from the [AWS Client VPN download](https://aws.amazon.com/jp/blogs/security/authenticate-aws-client-vpn-users-with-aws-single-sign-on/#:~:text=AWS%20Client%20VPN%20download).

- ***Note***: VPC and ACM are not necessary to set up before, because these will be generated in the CloudFormation stack you will create later.

## How to demo

- Create Cloudformation stack by using [templates/vpn-aws-side-vpc.yaml](./templates/vpn-aws-side-vpc.yaml).
- After the stack is created, access to the client VPC Endpoint Management console, check the client VPC endpoint and copy the Self-service portal URL displayed at the bottom of the screen.
- Access to the Self-service portal url in the browser then The AWS SSO signin screen will appear, and sign in. 
- click "Download client configuration"
  - ![Self-service portal](./images/AWS_Client_VPN_Self-Service_Portal.png)
- Start AWS VPN Client software on your windows or mac, then add a profile for your Client VPC endpoint using the downloaded configuration in you client software.
- Click "Connect" button on you client software.
- Once you have connected the Client VPC, get the private IP address of the web instance that has been created by the stack in the Management console, and access the private ip on browser.
- If the settings worked, you can see a screen similar to the following in your browser. **Note**: The local IP varies depending on the environment.
  - ![private web instance](./images/Hello_.png)
- Or you can test to ping to the private IP too.

## Clean up

- Delete the stack.
- Delete the certficate that is automaticaly createt in the stack in AWS Certificate manager. The certificate's name is such as <stackname>-Demo-server.
- Delete two IAM Identity providers.
- Delete two SSO Applications in you AWS SSO.


# Demo2: AWS Site-to-Site VPN

**Work in process**

![demo2-aws-site-to-site](./images/Site-to-Site-VPN-Demo.png)


Cloudformation Get Parameter
```
STACK_NAME=VPNDemo-SiteToSiteVPN

OnpreVPCID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[*].Outputs[?OutputKey==`OnpreVPCID`].OutputValue' --output text)
OnpreVPCPublicRouteTableID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[*].Outputs[?OutputKey==`OnpreVPCPublicRouteTableID`].OutputValue' --output text)
OnpreVPCPublicSubnetID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[*].Outputs[?OutputKey==`OnpreVPCPublicSubnetID`].OutputValue' --output text)
OnpreVPCRouterEIPID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[*].Outputs[?OutputKey==`OnpreVPCRouterEIPID`].OutputValue' --output text)

echo OnpreVPCID: $OnpreVPCID
echo OnpreVPCPublicRouteTableID: $OnpreVPCPublicRouteTableID
echo OnpreVPCPublicSubnetID: $OnpreVPCPublicSubnetID
echo OnpreVPCRouterEIPID: $OnpreVPCRouterEIPID
```

Grep VPN Connection settings from the donwloaded VPN Connection config file.

```
FILE_NAME=tmp/vpn-0d48797c1180b0d3f.txt

preshared_keys=$(grep '\-\ Pre-Shared Key' $FILE_NAME)
tunnel1_preshared_key=$(echo $preshared_keys | cut -d ' ' -f 5)
tunnel2_preshared_key=$(echo $preshared_keys | cut -d ' ' -f 10)

virtual_private_IPs=$(grep '\-\ Virtual Private Gateway' $FILE_NAME)
tunnel1_outside_vgw_ip=$(echo $virtual_private_IPs | cut -d ' ' -f 6)
tunnel1_inside_vgw_ip=$(echo $virtual_private_IPs | cut -d ' ' -f 12)
tunnel2_outside_vgw_ip=$(echo $virtual_private_IPs | cut -d ' ' -f 18)
tunnel2_inside_vgw_ip=$(echo $virtual_private_IPs | cut -d ' ' -f 24)

customer_gw_IPs=$(grep '\-\ Customer Gateway' $FILE_NAME)
tunnel1_inside_customer_gw_ip=$(echo $customer_gw_IPs | cut -d ' ' -f 10)
tunnel2_inside_customer_gw_ip=$(echo $customer_gw_IPs | cut -d ' ' -f 26)

bgp_neighbor_IPs=$(grep '\-\ Neighbor IP Address' $FILE_NAME)
tunnel1_bgp_neighbor_ip=$(echo $bgp_neighbor_IPs | cut -d ' ' -f 6)
tunnel2_bgp_neighbor_ip=$(echo $bgp_neighbor_IPs | cut -d ' ' -f 12)

echo tunnel1_preshared_key: $tunnel1_preshared_key
echo tunnel2_preshared_key: $tunnel2_preshared_key
echo tunnel1_outside_vgw_ip: $tunnel1_outside_vgw_ip
echo tunnel1_inside_vgw_ip: $tunnel1_inside_vgw_ip
echo tunnel2_outside_vgw_ip: $tunnel2_outside_vgw_ip
echo tunnel2_inside_vgw_ip: $tunnel2_inside_vgw_ip
echo tunnel1_inside_customer_gw_ip: $tunnel1_inside_customer_gw_ip
echo tunnel2_inside_customer_gw_ip: $tunnel2_inside_customer_gw_ip
echo tunnel1_bgp_neighbor_ip: $tunnel1_bgp_neighbor_ip
echo tunnel2_bgp_neighbor_ip: $tunnel2_bgp_neighbor_ip

```

Create Strongswan Instance
```


echo OnpreVPCID: $OnpreVPCID
echo OnpreVPCPublicRouteTableID: $OnpreVPCPublicRouteTableID
echo OnpreVPCPublicSubnetID: $OnpreVPCPublicSubnetID
echo OnpreVPCRouterEIPID: $OnpreVPCRouterEIPID
echo tunnel1_preshared_key: $tunnel1_preshared_key
echo tunnel2_preshared_key: $tunnel2_preshared_key
echo tunnel1_outside_vgw_ip: $tunnel1_outside_vgw_ip
echo tunnel1_inside_vgw_ip: $tunnel1_inside_vgw_ip
echo tunnel2_outside_vgw_ip: $tunnel2_outside_vgw_ip
echo tunnel2_inside_vgw_ip: $tunnel2_inside_vgw_ip
echo tunnel1_inside_customer_gw_ip: $tunnel1_inside_customer_gw_ip
echo tunnel2_inside_customer_gw_ip: $tunnel2_inside_customer_gw_ip
echo tunnel1_bgp_neighbor_ip: $tunnel1_bgp_neighbor_ip
echo tunnel2_bgp_neighbor_ip: $tunnel2_bgp_neighbor_ip

STRONGSWAN_STACK_NAME=VPNDemo-strongswan 

aws cloudformation create-stack --stack-name ${STRONGSWAN_STACK_NAME} \
    --template-body file://./templates/vpn-gateway-strongswan.yml \
    --parameters \
    ParameterKey=pVpcId,ParameterValue="${OnpreVPCID}" \
    ParameterKey=OnpreVPCPublicRouteTableID,ParameterValue="${OnpreVPCPublicRouteTableID}" \
    ParameterKey=pSubnetId,ParameterValue="${OnpreVPCPublicSubnetID}" \
    ParameterKey=pSubnetId,ParameterValue="${OnpreVPCPublicSubnetID}" \
    ParameterKey=pTunnel1PskKey,ParameterValue="${tunnel1_preshared_key}" \
    ParameterKey=pTunnel2PskKey,ParameterValue="${tunnel2_preshared_key}" \
    ParameterKey=pTunnel1VgwOutsideIpAddress,ParameterValue="${tunnel1_outside_vgw_ip}" \
    ParameterKey=pTunnel2VgwOutsideIpAddress,ParameterValue="${tunnel2_outside_vgw_ip}" \
    ParameterKey=pTunnel1CgwInsideIpAddress,ParameterValue="${tunnel1_inside_customer_gw_ip}" \
    ParameterKey=pTunnel2CgwInsideIpAddress,ParameterValue="${tunnel2_inside_customer_gw_ip}" \
    ParameterKey=pTunnel1VgwInsideIpAddress,ParameterValue="${tunnel1_inside_vgw_ip}" \
    ParameterKey=pTunnel2VgwInsideIpAddress,ParameterValue="${tunnel2_inside_vgw_ip}" \
    ParameterKey=pTunnel1BgpNeighborIpAddress,ParameterValue="${tunnel1_bgp_neighbor_ip}" \
    ParameterKey=pTunnel2BgpNeighborIpAddress,ParameterValue="${tunnel2_bgp_neighbor_ip}" \
    --capabilities CAPABILITY_NAMED_IAM
```