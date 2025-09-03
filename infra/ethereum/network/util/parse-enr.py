from enr import ENR

enr_string = "enr:-IS4QJ9Z...lYfJc4k"
enr = ENR.from_repr(enr_string)

print("IP:", enr.get("ip"))
print("TCP:", enr.get("tcp"))
print("UDP:", enr.get("udp"))
print("Public Key:", enr.public_key)
print("所有字段:", enr)
