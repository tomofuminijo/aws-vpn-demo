#!/bin/bash -eu

# Cloudformation Get Parameter
STACK_NAME=VPNDemo-SiteToSiteVPN

OnpreVPCID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[*].Outputs[?OutputKey==`OnpreVPCID`].OutputValue' --output text)
OnpreVPCPublicRouteTableID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[*].Outputs[?OutputKey==`OnpreVPCPublicRouteTableID`].OutputValue' --output text)
OnpreVPCPublicSubnetID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[*].Outputs[?OutputKey==`OnpreVPCPublicSubnetID`].OutputValue' --output text)
OnpreVPCRouterEIPID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[*].Outputs[?OutputKey==`OnpreVPCRouterEIPID`].OutputValue' --output text)
OnpreVPNConnectionID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[*].Outputs[?OutputKey==`OnpreVPNConnectionID`].OutputValue' --output text)

# Grep VPN Connection settings from the donwloaded VPN Connection config file.
# Download Connection Configuration file

DEVICE_TYPE_ID=$(aws ec2 get-vpn-connection-device-types --query 'VpnConnectionDeviceTypes[?Vendor==`Generic`].VpnConnectionDeviceTypeId' --output text)

aws ec2 get-vpn-connection-device-sample-configuration  \
    --vpn-connection-id $OnpreVPNConnectionID  \
    --vpn-connection-device-type-id $DEVICE_TYPE_ID  \
    --query 'VpnConnectionDeviceSampleConfiguration' \
    --output text > vpn-configure.txt

FILE_NAME=vpn-configure.txt

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

# Create Strongswan Instance using CloudFormation

echo OnpreVPCID: $OnpreVPCID
echo OnpreVPCPublicRouteTableID: $OnpreVPCPublicRouteTableID
echo OnpreVPCPublicSubnetID: $OnpreVPCPublicSubnetID
echo OnpreVPCRouterEIPID: $OnpreVPCRouterEIPID
echo tunnel1_preshared_key: $tunnel1_preshared_key
echo tunnel2_preshared_key: $tunnel2_preshared_key
echo tunnel1_outside_vgw_ip: $tunnel1_outside_vgw_ip
echo tunnel2_outside_vgw_ip: $tunnel2_outside_vgw_ip
echo tunnel1_inside_customer_gw_ip: $tunnel1_inside_customer_gw_ip
echo tunnel2_inside_customer_gw_ip: $tunnel2_inside_customer_gw_ip
echo tunnel1_inside_vgw_ip: $tunnel1_inside_vgw_ip
echo tunnel2_inside_vgw_ip: $tunnel2_inside_vgw_ip
echo tunnel1_bgp_neighbor_ip: $tunnel1_bgp_neighbor_ip
echo tunnel2_bgp_neighbor_ip: $tunnel2_bgp_neighbor_ip

STRONGSWAN_STACK_NAME=VPNDemo-strongswan 

aws cloudformation create-stack --stack-name ${STRONGSWAN_STACK_NAME} \
    --template-body file://./templates/vpn-gateway-strongswan.yml \
    --parameters \
    ParameterKey=pVpcId,ParameterValue="${OnpreVPCID}" \
    ParameterKey=OnpreVPCPublicRouteTableID,ParameterValue="${OnpreVPCPublicRouteTableID}" \
    ParameterKey=pSubnetId,ParameterValue="${OnpreVPCPublicSubnetID}" \
    ParameterKey=pEipAllocationId,ParameterValue="${OnpreVPCRouterEIPID}" \
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
