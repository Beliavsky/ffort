program main
implicit none
interface twice
procedure twice_int
end interface
print *,twice(4)
contains
integer function twice_int(x) result(y)
integer,intent(in)::x
y=2*x
end function
end program
