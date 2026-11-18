program purity_test
implicit none
integer :: aa(-2:2)
aa=3
print *,compute(aa(2:-2:-2))
contains
pure integer function compute(xx) result(rr)
integer,intent(in)::xx(:)
rr=sum(array=xx)+product(xx)+size(xx)
end function compute

end program
