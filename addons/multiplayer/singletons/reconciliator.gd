extends Node


signal rollback(new_state: Dictionary)
signal simulate_frame(inputs: Dictionary)


func _client_acknowledge_input(last_acknowledged_input: int) -> Array:
	# removes the acknowledged input id and everything before it
	# returns list of inputs before it
	var input_numbers := Inputs._client_unacknowledged_inputs.keys()
	input_numbers.sort()
	for number in input_numbers:
		if number <= last_acknowledged_input:
			input_numbers.erase(number)
			Inputs._client_unacknowledged_inputs.erase(number)
	return input_numbers


func _reconciliate_client_blob(new_state: Dictionary, input_number: int) -> void:
	var unacknowledged_inputs := _client_acknowledge_input(input_number)
	rollback.emit(new_state)
	for number in unacknowledged_inputs:
		simulate_frame.emit(Inputs._client_unacknowledged_inputs[number])
