program main
implicit none
integer,pointer::i
integer,target::x
integer::a(3)
x=99
i=>x
a=[(i,i=1,3)]
print *,a,x,i
end program
