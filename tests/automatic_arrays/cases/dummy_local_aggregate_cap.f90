program demo
implicit none
integer::xx(500001)
call work(xx)
contains
subroutine work(xx)
integer,intent(in)::xx(:)
integer::aa(size(xx))
print *,123
end subroutine
end program
