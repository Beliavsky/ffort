implicit none
character(3)::a(3)=[character(3)::"a","b","c"]
a=a(3:1:-1)//a(1)
print *,a
end
