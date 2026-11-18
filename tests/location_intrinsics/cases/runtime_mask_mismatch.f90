program p
implicit none
integer::a(3),n
logical::m(3)
a=[1,2,3]
n=2
print *,minloc(a,mask=m(:n))
end program
