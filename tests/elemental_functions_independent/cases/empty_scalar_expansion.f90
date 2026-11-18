program elemental_test
implicit none
integer::aa(0)
print *,combine(aa,5),combine(5,aa)
print *,size(combine(aa,5))
contains
elemental integer function combine(xx,yy) result(rr)
integer,intent(in)::yy,xx
rr=10*xx+yy
end function combine

end program
