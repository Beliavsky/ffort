program p
implicit none
integer::a(0,3),b(0,3),s(3)
a=0
s(1)=1
s(3)=1
b=cshift(a,s)
print *, "PASS"
end program
