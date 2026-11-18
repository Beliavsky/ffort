program main
implicit none
real(4)::a(2)
call inspect()
call inspect(a)
contains
subroutine inspect(x)
real(4),optional,intent(in)::x(:)
integer,parameter::l=minexponent(x),u=maxexponent(x)
print *,present(x),l,u,kind(maxexponent(x))
end subroutine
end program
