const net_client = require("../net/net_client")

const result = net_client.scope.my_func.invoke("foo", true)

print(result)
