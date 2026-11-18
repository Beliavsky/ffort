program main
implicit none
integer::i,a(6)
i=88
a=[(i,see_outer(),i=1,3)]
print *,a,i
contains
integer function see_outer() result(r)
r=i
end function
end program
