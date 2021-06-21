def grabEnvFile():
    with open(".env", "r") as my_fil:
        key_lines = my_fil.read().split("\n")
        print(key_lines)
        ENV_STRUCT = {k.split("=")[0] : k.split("=")[1]  for k in key_lines if k}
    return ENV_STRUCT
