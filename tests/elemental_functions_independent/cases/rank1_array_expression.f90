program elemental_test
implicit none
integer::aa(-1:1)
aa(-1)=1
aa(0)=2
aa(1)=3
print *,combine(aa+1,compute(aa))
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
