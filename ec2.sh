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