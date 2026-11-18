program p
implicit none
integer,parameter::k=8,n=3
real(k) x
character(n) c
x=1.25_8
c='abc'
print *,x,c
end program
