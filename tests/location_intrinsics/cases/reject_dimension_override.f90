program test
implicit none
integer,dimension(4)::a(2)
a=[2,1]
print *,minloc(a)
end program
