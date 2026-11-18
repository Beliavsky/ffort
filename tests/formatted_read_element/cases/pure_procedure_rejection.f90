program main
implicit none
integer::u=27,ios
character(4)::a(2)
call take(u,a)
contains
pure subroutine take(unit,x)
integer,intent(in)::unit
character(*),intent(out)::x(:)
read(unit,'(a)')x(1)
end subroutine
end program
