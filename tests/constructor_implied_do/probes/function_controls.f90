program main
implicit none
integer::i,a(3)
i=99
a=[(i,i=ident(1),ident(3),ident(1))]
print *,a,i
contains
integer function ident(x)
integer,intent(in)::x
ident=x
end function
end program
