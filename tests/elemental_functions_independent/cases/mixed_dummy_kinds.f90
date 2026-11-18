program elemental_test
implicit none
real::aa(2)
real(8)::bb(2)
aa=0.5
bb=0.25d0
print *,combine(yy=bb,xx=aa)
contains
elemental real(8) function combine(xx,yy) result(rr)
real,intent(in)::xx
real(8),intent(in)::yy
rr=xx+yy
end function combine

end program
