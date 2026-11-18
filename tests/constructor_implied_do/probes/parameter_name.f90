program main
implicit none
integer,parameter::i=99
integer::a(3)
a=[(i,i=1,3)]
print *,a,i
end program
