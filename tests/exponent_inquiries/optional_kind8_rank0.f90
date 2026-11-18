program main
implicit none
real(8)::a
call inspect()
call inspect(a)
contains
subroutine inspect(x)
real(8),optional,intent(in)::x
integer,parameter::l=minexponent(x),u=maxexponent(x)
print *,present(x),l,u,kind(maxexponent(x))
end subroutine
end program
