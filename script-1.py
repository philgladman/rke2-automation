import json
print("-----start-----")

## or open file with this > with open
with open('script-output.json', 'r') as test_outputs_file:
    test_data = json.load(test_outputs_file)
    # print(test_data)
    for i in test_data:
        with open("script-variables-output.txt", "a") as out_file:
            if i[0] == "MasterPrivateIP":
                print("master_ipaddress: " + i[1], file=out_file)
            if i[0] == "Worker01PrivateIP":
                print("worker01_ipaddress: " + i[1], file=out_file)
            if i[0] == "Worker02PrivateIP":
                print("worker02_ipaddress: " + i[1], file=out_file)
            if i[0] == "Worker03PrivateIP":
                print("worker03_ipaddress: " + i[1], file=out_file)
                """
        if i[0] == "MasterPrivateIP":
            print("master_ipaddress: " + i[1])
        if i[0] == "Worker01PrivateIP":
            print("worker01_ipaddress: " + i[1])
        if i[0] == "Worker02PrivateIP":
            print("worker02_ipaddress: " + i[1])
        if i[0] == "Worker03PrivateIP":
            print("worker03_ipaddress: " + i[1])
            """
    # print(json.dumps(test_data, indent=4))

# file_contents = open("/Users/Philgladman/Desktop/DevOps/cloudformation/test-outputs.json", 'r').read()
# s = json.loads(file_contents)
# print(file_contents[2])




print("-----finish-----")