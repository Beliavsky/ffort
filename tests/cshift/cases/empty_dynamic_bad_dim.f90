program p
implicit none
integer::a(0,3),b(0,3),d
a=0
d=0
b=cshift(a,[1,2,3],d)
print *, "PASS"
end program
