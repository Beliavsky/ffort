program p
implicit none
integer::a(2,3),b(2,3)
integer(8)::d
a=1
d=3
b=cshift(a,1,d)
print *, "PASS"
end program
