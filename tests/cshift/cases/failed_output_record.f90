program p
implicit none
integer::a(3),d
a=[1,2,3]
d=0
print '(a)', "BEFORE"
print *, "partial", cshift(a,1,d)
end program
