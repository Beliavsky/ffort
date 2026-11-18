program purity_test
implicit none
integer :: aa
aa=9
print *,combine(aa,aa)
contains
simple integer function combine(xx,yy) result(rr)
integer,intent(in)::xx,yy
rr=xx+yy
end function

end program
