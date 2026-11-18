program elemental_test
implicit none
integer::aa(2),bb(2)
aa=2
bb=1
print *,combine(compute(aa),bb)
contains
elemental integer function combine(xx,yy) result(rr)
integer,intent(in)::yy,xx
rr=10*xx+yy
end function combine
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
