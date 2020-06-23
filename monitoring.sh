#!/bin/bash

#default env variable
account_id="dsrv.betanet"
validator_id="staking.dsrv.betanet"
rpc_call="http post https://rpc.betanet.near.org jsonrpc=2.0"


content=$($rpc_call id=dontcare method=block params:='{"finality": "final"}') 
current_epoch_id=$( jq -r '.result.header.epoch_id' <<< $content )
height=$( jq -r '.result.header.height' <<< $content )
epoch_start_height=$($rpc_call method=validators params:='[null]' id=dontcare | jq -r .result.epoch_start_height)

echo "warchest bot shared by dsrvlabs!"
echo curreunt epoch_id: $current_epoch_id
echo epoch start from: $epoch_start_height
echo current block height: $height

while true
do
	content=$($rpc_call id=dontcare method=block params:='{"finality": "final"}') 
	next_epoch_id=$( jq -r '.result.header.epoch_id' <<< $content )
	height=$( jq -r '.result.header.height' <<< $content )
	epoch_start_height=$($rpc_call method=validators params:='[null]' id=dontcare | jq -r .result.epoch_start_height)

	target=""

	if [ "$current_epoch_id" != "$next_epoch_id" ]; then
		#epoch chagned: PING!
		near call $validator_id stake '{"amount": "'$target'"}' --accountId=$account_id

		echo "epoch chaged, ping!" 
		near call $validator_id  ping '{}' --accountId=$account_id

		echo "epoch changed from $current to $next"
		echo "block height is $height"
		current=$next

		content=$($rpc_call method=validators params:='[null]' id=dontcare)p
		vali_cur=$( jq -r '.result.current_validators' <<< $content | grep $validator_id | wc -l )
		vali_nex=$( jq -r '.result.next_validators' <<< $content | grep $validator_id | wc -l )

 		#python3 dsrv_email_sender.py "current epoch $vali_cur, next epoch $vali_nex"
	else
		#epoch chagned: report status
		content=$($rpc_call method=validators params:='[null]' id=dontcare)	
		vali_cur=$( jq -r '.result.current_validators' <<< $content | grep $validator_id | wc -l )
		vali_nex=$( jq -r '.result.next_validators' <<< $content | grep $validator_id | wc -l )

		echo "=== $validator_id validator status ===" 
		echo "current epoch $vali_cur, next epoch $vali_nex"
		echo "1 epoch size 10000 betanet" 
		now_height=`expr $height - $epoch_start_height`
		echo epoch pogress `expr $now_height / 100`%


		my_staking_status=$(near state $validator_id | awk '/locked/{print substr($2,7, length($2)-13)}' | sed 's/,//g')
		current_seat_price=$(near validators current | awk '/price/ {print substr($6, 1, length($6)-2)}'| sed 's/,//g')
		next_seat_price=$(near validators next | awk '/price/ {print substr($7, 1, length($7)-2)}'| sed 's/,//g')
		next_next_seat_price=$(near proposals | awk '/price =/ {print substr($15, 1, length($15)-1)}'| sed 's/,//g')

		echo pool_locked_token: $my_staking_status 
		echo t+0 seat price: $current_seat_price
		echo t+1 seat price: $next_seat_price
		echo t+2 seat price: $next_next_seat_price

		#do something for challenge004, simply next 
		target=${next_seat_price}000000000000000000000000
		echo next target price: $target
	fi
	sleep 10
done



