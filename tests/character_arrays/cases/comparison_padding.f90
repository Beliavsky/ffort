implicit none
character(3)::a(2)=[character(3)::"a","b"]
print *,a=="a",a<"b",a/="b  ","b">=a
end
