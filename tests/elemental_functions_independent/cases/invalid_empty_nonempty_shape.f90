program elemental_test
implicit none
integer::aa(0),bb(2)
bb=3
print *,combine(aa,bb)
contains
elemental integer function combine(xx,yy) result(rr)
integer,intent(in)::yy,xx
rr=10*xx+yy
end function combine

end program
