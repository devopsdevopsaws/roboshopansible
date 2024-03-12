#!/bin/bash
N=$@
INSTANCE_TYPE=""
ami_id=ami-0f3c7d07486cad139
sg_id=sg-0d4abb7ec63105dd5
hosted_zone_id=Z020064935UZCTKXJV1XV
domain_name=padmasrikanth.shop
for i in $@
do
    if [[ $i == "mysql" || $i == "mongodb" ]]
    then 
    INSTANCE_TYPE=t2.micro
    else
    INSTANCE_TYPE=t2.micro
    fi
    instance_ids=$(aws ec2 describe-instances --filters Name=tag:Name,Values="'$i'" | jq -r '.Reservations[].Instances[].InstanceId')
    for instance_id in $instance_ids
    do
        running=$(aws ec2 describe-instances --instance-ids $instance_id | jq -r '.Reservations[].Instances[].State.Name')
            if [ "$running" == "running" ]
            then 
                echo "The EC2 instance $i --> $instance_id is already running. Not launching a new instance."
                exit 1
            fi
    done
    echo "Creating $i instance"
    j=$(aws ec2 run-instances --image-id $ami_id --instance-type $INSTANCE_TYPE --security-group-ids $sg_id --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" | jq -r '.Instances[0].PrivateIpAddress')
    echo "Respective private for the $i instance is $j" 
    aws route53 change-resource-record-sets --hosted-zone-id $hosted_zone_id --change-batch '
    {
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'$i.$domain_name'",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [{ "Value": "'$j'"}]
                }
            }
        ]
    }'
done


#!/bin/bash

NAMES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "web")
INSTANCE_TYPE=""
IMAGE_ID=ami-0f3c7d07486cad139
SECURITY_GROUP_ID=sg-0d4abb7ec63105dd5
DOMAIN_NAME=padmasrikanth.shop

# if mysql or mongodb instance_type should be t3.medium , for all others it is t2.micro

for i in "${NAMES[@]}"
do  
    if [[ $i == "mongodb" || $i == "mysql" ]]
    then
        INSTANCE_TYPE="t3.medium"
    else
        INSTANCE_TYPE="t2.micro"
    fi
    echo "creating $i instance"
    IP_ADDRESS=$(aws ec2 run-instances --image-id $IMAGE_ID  --instance-type $INSTANCE_TYPE --security-group-ids $SECURITY_GROUP_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" | jq -r '.Instances[0].PrivateIpAddress')
    echo "created $i instance: $IP_ADDRESS"

    aws route53 change-resource-record-sets --hosted-zone-id Z020064935UZCTKXJV1XV --change-batch '
    {
            "Changes": [{
            "Action": "CREATE",
                        "ResourceRecordSet": {
                            "Name": "'$i.$DOMAIN_NAME'",
                            "Type": "A",
                            "TTL": 300,
                            "ResourceRecords": [{ "Value": "'$IP_ADDRESS'"}]
                        }}]
    }
    '
done

# imporvement
# check instance is already created or not
# update route53 record