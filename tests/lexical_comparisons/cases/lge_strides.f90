program p
implicit none
character(2)::a(4)
character(3)::b(4)
a=['ab','cd','ef','gh']
b=['ab ','cd ','zz ','aa ']
print *,lge(a(4:1:-2),b(1:4:2))
end program
