program p
implicit none
integer::a(2,3),b(2,3),s(3)
a=1
s(1)=0
s(2)=0
b=cshift(a,s)
print *, "PASS"
end program
