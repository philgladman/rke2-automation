import json
import os
print("-----start-----")

## or open file with this > with open
with open(os.path.expanduser('~/rke2-automation/create-ec2-instances/script-output.json'), 'r') as test_outputs_file:
    test_data = json.load(test_outputs_file)

    for i in test_data:
        with open(os.path.expanduser("~/rke2-automation/ansible-rke2/group_vars/all"), "a") as out_file:
            if i[0] == "MasterPrivateIP":
                print("master_ipaddress: " + i[1], file=out_file)
            if i[0] == "Worker01PrivateIP":
                print("worker01_ipaddress: " + i[1], file=out_file)
            if i[0] == "Worker02PrivateIP":
                print("worker02_ipaddress: " + i[1], file=out_file)
            if i[0] == "Worker03PrivateIP":
                print("worker03_ipaddress: " + i[1], file=out_file)

print("-----finish-----")